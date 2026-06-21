## 🚀 Requisitos

- Terraform CLI >= 1.0
- Docker Desktop corriendo
- AWS CLI configurado con credenciales de AWS Academy
- Git

---

## ⚙️ Flujo de despliegue

### 1. Configurar credenciales AWS Academy
```bash
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key xxx...
aws configure set aws_session_token xxx...
aws configure set region us-east-1
```

### 2. Crear infraestructura con Terraform
```bash
cd terraform
terraform init
terraform apply
```
Esto crea: VPC, subredes pública/privada, Security Groups, repositorios ECR y 3 instancias EC2 (frontend, backend-despachos y backend-ventas).

### 3. Build y Push de imágenes a ECR
```bash
# Login en ECR (Windows)
$token = aws ecr get-login-password --region us-east-1
docker login --username AWS --password $token TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Frontend
docker build -t TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend:latest ./front_despacho
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend:latest

# Backend Despachos
docker build -t TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-despachos:latest ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-despachos:latest

# Backend Ventas
docker build -t TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-ventas:latest ./back-Ventas_SpringBoot/Springboot-API-REST
docker push TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-ventas:latest
```

### 4. Conectarse a la EC2 Frontend y levantar contenedor
```bash
ssh -i labsuser.pem ec2-user@IP_PUBLICA_FRONTEND

# Dentro de la EC2:
aws configure set aws_access_key_id ASIA...
aws configure set aws_secret_access_key xxx...
aws configure set aws_session_token xxx...
aws configure set region us-east-1

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker run -d \
  --name frontend \
  -p 80:80 \
  TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-frontend:latest
```

### 5. Conectarse a las EC2 de Backend y levantar cada contenedor

Cada API vive en su propia instancia. El Security Group de cada una solo permite tráfico en el puerto de la app desde el Security Group del Frontend (no desde Internet); el acceso por SSH se usa únicamente para administración.

```bash
# --- Backend Despachos (puerto 8081) ---
ssh -i labsuser.pem ec2-user@IP_PUBLICA_BACKEND_DESPACHOS

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker run -d \
  --name backend-despachos \
  -p 8081:8081 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/innovatech_db \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-despachos:latest
```

```bash
# --- Backend Ventas (puerto 8080) ---
ssh -i labsuser.pem ec2-user@IP_PUBLICA_BACKEND_VENTAS

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker run -d \
  --name backend-ventas \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/innovatech_db \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  TU_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech-backend-ventas:latest
```

> El Frontend debe apuntar a las IPs (o nombres DNS internos) de estas dos instancias para consumir cada API.

### 6. Verificar
```bash
docker ps
```
Abrir navegador en `http://IP_PUBLICA_FRONTEND`

---

## 🏗️ Infraestructura AWS

- **VPC:** 10.0.0.0/16
- **Subred pública:** 10.0.1.0/24 → EC2 Frontend (IP pública), EC2 Backend Despachos, EC2 Backend Ventas
- **Security Group Frontend:** puertos 80, 443, 22 abiertos a Internet (único punto de entrada público)
- **Security Group Backend Despachos:** puerto 8081 solo desde el SG del Frontend
- **Security Group Backend Ventas:** puerto 8080 solo desde el SG del Frontend
- **ECR:** 3 repositorios (frontend, backend-despachos, backend-ventas)

---

## 📌 Mejores prácticas aplicadas

- Dockerfiles con **multi-stage build** para imágenes livianas
- **Usuario no-root** en contenedores backend
- **HEALTHCHECK** en todos los contenedores
- **Named volumes** para persistencia de datos
- **Redes Docker** para comunicación entre contenedores
- **GitHub Secrets** para credenciales AWS en pipelines CI/CD
- Infraestructura como código con **Terraform**