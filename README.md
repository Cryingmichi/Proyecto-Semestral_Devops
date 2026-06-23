## 🚀 Requisitos

- Terraform CLI >= 1.0
- Docker Desktop corriendo
- AWS CLI configurado con credenciales de AWS Academy Learner Lab
- kubectl
- Git
- Cuenta de AWS Academy Learner Lab (provee los roles `LabEKSClusterRole` y `LabEKSNodeRole` reutilizados por la infraestructura)

---

## 🏗️ Arquitectura

La aplicación corre orquestada en **AWS EKS** (Kubernetes administrado). El único punto público es el **Service `frontend-service`** (tipo `LoadBalancer`); los backends y la base de datos son internos al clúster.

```
Internet
   │
   ▼
 [LoadBalancer] (único punto de entrada público)
   │
   ▼
 [Pod Frontend] (Nginx)
   │  proxy_pass interno según el path
   ├── /api/v1/despachos*  → despachos-service (ClusterIP, interno)
   └── /api/v1/ventas*      → ventas-service (ClusterIP, interno)
                                   │
                                   ▼
                          mysql-service (ClusterIP, interno)
```

- **Clúster EKS:** `innovatech-eks`, con un Node Group de instancias SPOT `t3.large` (1 a 3 nodos).
- **Namespace dedicado:** `innovatech` (todos los recursos de la app viven ahí).
- **3 Deployments + Services de aplicación:** `frontend` (público, `LoadBalancer`), `backend-despachos` y `backend-ventas` (internos, `ClusterIP`).
- **MySQL** corre como un Deployment más (`mysql`), expuesto solo internamente vía `mysql-service`; los backends lo encuentran por DNS interno de Kubernetes (`mysql-service.innovatech.svc.cluster.local`) usando CoreDNS — nativo del clúster, sin depender de servicios adicionales de AWS.
- **El frontend (Nginx) hace de proxy reverso** hacia los backends internos (ver `front_despacho/nginx.conf`), de modo que el navegador solo necesita llamar al mismo dominio público del LoadBalancer.
- **Autoscaling:** `HorizontalPodAutoscaler` al 50% de CPU en los 3 Deployments de aplicación (ver justificación en `k8s/hpa.yaml`). Requiere el addon `metrics-server`.
- **Secrets:** la contraseña de MySQL se gestiona como `Secret` de Kubernetes (`db-credentials`), nunca en texto plano en el repositorio.
- **Logs:** vía `kubectl logs`, o los logs del control plane en CloudWatch (habilitados en el clúster).

---

## ⚙️ Despliegue inicial de la infraestructura

### 1. Configurar credenciales AWS Academy
```bash
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key xxx...
aws configure set aws_session_token xxx...
aws configure set region us-east-1
```

> En AWS Academy Learner Lab las credenciales son temporales (STS). Cuando el laboratorio se reinicia hay que repetir este paso y actualizar los Secrets en GitHub (ver sección de CI/CD más abajo).

### 2. Crear infraestructura con Terraform
```bash
cd terraform
terraform init
terraform apply
```
Esto crea: VPC con 2 subredes públicas (en 2 AZs, etiquetadas para Kubernetes), los repositorios ECR, el clúster EKS, el Node Group, y los addons `vpc-cni`, `coredns`, `kube-proxy` y `metrics-server`.

⏱️ El clúster EKS puede tardar entre 10 y 15 minutos en quedar `ACTIVE`.

### 3. Conectar kubectl al clúster
```bash
aws eks update-kubeconfig --region us-east-1 --name innovatech-eks
kubectl get nodes
```

### 4. Crear el namespace y el Secret de base de datos
```bash
kubectl apply -f k8s/namespace.yaml

kubectl create secret generic db-credentials \
  --namespace=innovatech \
  --from-literal=MYSQL_ROOT_PASSWORD='TU_PASSWORD_SEGURA' \
  --from-literal=DB_USERNAME=root \
  --from-literal=DB_PASSWORD='TU_PASSWORD_SEGURA'
```

> No se versiona ninguna contraseña real en el repositorio. `k8s/secret.yaml.example` es solo una plantilla de referencia.

### 5. Primer build y push de imágenes a ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker build -t TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend:latest ./front_despacho
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend:latest

docker build -t TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-despachos:latest ./back-Despachos_SpringBoot
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-despachos:latest

docker build -t TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-ventas:latest ./back-Ventas_SpringBoot
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-ventas:latest
```

### 6. Aplicar los manifiestos de Kubernetes

Antes de aplicar, reemplaza `905417999966` (o el Account ID usado de ejemplo) por tu Account ID real en `k8s/despachos.yaml`, `k8s/ventas.yaml` y `k8s/frontend.yaml` si difiere.

```bash
kubectl apply -f k8s/mysql.yaml
kubectl apply -f k8s/despachos.yaml
kubectl apply -f k8s/ventas.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/hpa.yaml
```

### 7. Verificar

```bash
kubectl get pods -n innovatech
kubectl get svc -n innovatech
```

El `frontend-service` mostrará un `EXTERNAL-IP` (DNS del LoadBalancer) una vez que AWS termine de aprovisionarlo (puede tardar 1-2 minutos). Esa es la URL pública de la aplicación.

---

## 🔄 Pipeline CI/CD (GitHub Actions)

Cada componente tiene su propio workflow en `.github/workflows/`, disparado al hacer push a la rama `main` con cambios en su carpeta correspondiente:

| Workflow | Carpeta vigilada | Deployment de Kubernetes |
|---|---|---|
| `deplay-frontend.yml` | `front_despacho/**` | `frontend` |
| `deplay-despacho.yml` | `back-Despachos_SpringBoot/**` | `backend-despachos` |
| `deplay-ventas.yml` | `back-Ventas_SpringBoot/**` | `backend-ventas` |

Flujo de cada pipeline (build → push → deploy):
1. **Build** de la imagen Docker, etiquetada con el número de build (`GITHUB_RUN_NUMBER`) y además `latest`.
2. **Push** de ambos tags a Amazon ECR.
3. Configura `kubectl` contra el clúster EKS.
4. **Deploy**: `kubectl set image` actualiza el Deployment con la nueva imagen, y `kubectl rollout status` espera a que el rolling update termine con éxito (si falla, el job de GitHub Actions falla).

### Secrets requeridos en GitHub (Settings → Secrets and variables → Actions)

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key temporal de AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Secret key temporal de AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión STS (obligatorio en Learner Lab) |
| `AWS_ACCOUNT_ID` | ID de la cuenta AWS (para construir las URLs de ECR) |

> Importante: en Learner Lab las credenciales expiran cada vez que el laboratorio se reinicia. Cuando eso ocurra, hay que volver a generarlas y actualizar los 3 secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_SESSION_TOKEN` en GitHub antes de que el pipeline vuelva a funcionar. El rol IAM que asumen estas credenciales debe tener permisos sobre EKS (`eks:DescribeCluster`, etc.); el rol `voclabs` del lab ya los incluye.

### Disparar un despliegue
```bash
git add .
git commit -m "feat: actualizacion de servicio"
git push origin main
```

### Revisar el resultado del despliegue
- En GitHub: pestaña **Actions**, revisar el log del job (incluye el resultado de `kubectl rollout status`: si el rollout falla, el job falla).
- En AWS/kubectl:
  ```bash
  kubectl get deployments -n innovatech
  kubectl rollout history deployment/backend-despachos -n innovatech
  kubectl logs -n innovatech deployment/backend-despachos --tail=100
  ```

---

## 📈 Autoscaling

Cada Deployment de aplicación (`frontend`, `backend-despachos`, `backend-ventas`) tiene un `HorizontalPodAutoscaler` basado en el promedio de CPU de sus pods:

- **Umbral:** 50% de CPU.
- **Mínimo:** 1 réplica. **Máximo:** 3 réplicas.
- **Justificación:** un umbral de 50% deja margen para absorber picos de tráfico sin saturar el pod mientras Kubernetes aprovisiona uno nuevo, evitando degradar tiempos de respuesta. Un umbral más bajo (ej. 20%) generaría escalados innecesarios ante cargas normales; uno más alto (ej. 80%) arriesgaría saturar el servicio antes de que termine de escalar.

Para observar el autoscaling en vivo:
```bash
kubectl get hpa -n innovatech --watch
```

Para generar carga de prueba:
```bash
# Ejemplo simple con hey (https://github.com/rakyll/hey)
hey -z 2m -c 50 http://<EXTERNAL-IP-DEL-FRONTEND>/api/v1/ventas
```

---

## 🔐 Gestión de Secrets

La contraseña de la base de datos MySQL **no** se almacena en código ni en variables de entorno en texto plano:

- Se crea como un `Secret` nativo de Kubernetes (`db-credentials`) mediante `kubectl create secret`, fuera del control de versiones.
- Los Deployments de `mysql`, `backend-despachos` y `backend-ventas` la referencian mediante `secretKeyRef` / `envFrom.secretRef`, nunca como valor literal en los manifiestos versionados.
- `k8s/secret.yaml.example` es solo una plantilla documental; no debe aplicarse tal cual ni commitearse con una contraseña real.
- Las credenciales de AWS para el pipeline (incluyendo el `AWS_SESSION_TOKEN` temporal de Learner Lab) se gestionan exclusivamente como **GitHub Secrets**.

---

## 📌 Mejores prácticas aplicadas

- Dockerfiles con **multi-stage build** para imágenes livianas
- **Usuario no-root** en contenedores backend
- **HEALTHCHECK/Probes** basados en `/actuator/health` en los backends (Docker HEALTHCHECK + readiness/liveness probes de Kubernetes)
- **DNS interno de Kubernetes (CoreDNS)** para la comunicación backend → base de datos
- **Kubernetes Secrets** para credenciales sensibles
- **GitHub Secrets** para credenciales AWS en pipelines CI/CD
- **Autoscaling** basado en métricas reales de CPU (HPA + metrics-server)
- Infraestructura como código con **Terraform** (clúster, networking, ECR)
- Manifiestos de Kubernetes como código (`k8s/`)
- Pipeline CI/CD versionado (tags únicos por build, no solo `latest`) con verificación de rollout exitoso
