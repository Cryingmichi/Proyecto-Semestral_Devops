#!/bin/bash
# Levanta TODO el proyecto desde cero, asumiendo que el laboratorio
# se acaba de resetear (no existe nada todavia: ni cluster, ni ECR
# con imagenes, ni recursos de Kubernetes).
#
# Requisito previo: haber corrido ./renovar-creds.sh (o configurado
# las credenciales de AWS a mano) antes de ejecutar este script.
#
# Uso: ./deploy-all.sh

set -e

AWS_REGION="us-east-1"
ACCOUNT_ID="905417999966"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
CLUSTER_NAME="innovatech-eks"
DB_PASSWORD="Innovatech2026!"

echo "=== 0/7: Verificando credenciales de AWS ==="
aws sts get-caller-identity > /dev/null || {
  echo "Las credenciales de AWS no son validas. Corre ./renovar-creds.sh primero."
  exit 1
}
echo "Credenciales OK."

echo
echo "=== 1/7: Creando infraestructura con Terraform (cluster EKS, VPC, ECR) ==="
echo "Esto puede tardar entre 10 y 15 minutos la primera vez."
cd terraform
terraform init -input=false
terraform apply -auto-approve
cd ..

echo
echo "=== 2/7: Conectando kubectl al cluster ==="
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "Esperando a que el Node Group este Ready (hasta 3 min)..."
for i in $(seq 1 18); do
  READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || true)
  if [ "$READY_NODES" -ge 1 ]; then
    echo "Nodo(s) Ready: $READY_NODES"
    break
  fi
  echo "Esperando nodos... (intento $i/18)"
  sleep 10
done
kubectl get nodes

echo
echo "=== 3/7: Login en ECR ==="
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo
echo "=== 4/7: Namespace y Secret de base de datos ==="
kubectl apply -f k8s/namespace.yaml

if kubectl get secret db-credentials -n innovatech >/dev/null 2>&1; then
  echo "Secret db-credentials ya existe, no se vuelve a crear."
else
  kubectl create secret generic db-credentials \
    --namespace=innovatech \
    --from-literal=MYSQL_ROOT_PASSWORD="$DB_PASSWORD" \
    --from-literal=DB_USERNAME=root \
    --from-literal=DB_PASSWORD="$DB_PASSWORD"
  echo "Secret db-credentials creado."
fi

echo
echo "=== 5/7: Build y push de las 3 imagenes ==="

echo "--- Frontend ---"
docker build -t "${REGISTRY}/innovatech-frontend:latest" ./front_despacho
docker push "${REGISTRY}/innovatech-frontend:latest"

echo "--- Backend Despachos ---"
docker build -t "${REGISTRY}/innovatech-backend-despachos:latest" ./back-Despachos_SpringBoot
docker push "${REGISTRY}/innovatech-backend-despachos:latest"

echo "--- Backend Ventas ---"
docker build -t "${REGISTRY}/innovatech-backend-ventas:latest" ./back-Ventas_SpringBoot
docker push "${REGISTRY}/innovatech-backend-ventas:latest"

echo
echo "=== 6/7: Aplicando manifiestos de Kubernetes ==="
kubectl apply -f k8s/mysql.yaml
kubectl apply -f k8s/despachos.yaml
kubectl apply -f k8s/ventas.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/hpa.yaml

echo
echo "=== 7/7: Esperando a que los pods queden listos (hasta 5 min) ==="
kubectl wait --for=condition=available --timeout=300s deployment/mysql -n innovatech || true
kubectl wait --for=condition=available --timeout=300s deployment/backend-despachos -n innovatech || true
kubectl wait --for=condition=available --timeout=300s deployment/backend-ventas -n innovatech || true
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n innovatech || true

echo
echo "=== Estado final ==="
kubectl get pods -n innovatech
echo
kubectl get svc frontend-service -n innovatech

echo
echo "=================================================================="
echo " Listo. La URL publica del frontend es el EXTERNAL-IP de arriba."
echo " Si todavia dice 'pending', espera 1-2 minutos y vuelve a correr:"
echo "   kubectl get svc frontend-service -n innovatech"
echo
echo " RECORDATORIO: actualiza tambien los GitHub Secrets"
echo " (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)"
echo " para que el pipeline de CI/CD funcione con las nuevas credenciales."
echo "=================================================================="
