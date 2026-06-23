#!/bin/bash
# Renueva las credenciales de AWS Academy Learner Lab.
# Uso: ./renovar-creds.sh
# Pide los 3 valores del bloque "AWS Details -> CLI" del laboratorio
# y los configura con aws configure set. No imprime ni guarda los
# valores en ningun archivo de log.

set -e

echo "=== Renovar credenciales de AWS Academy Learner Lab ==="
echo "Copia los valores desde 'AWS Details -> CLI' en el laboratorio."
echo

read -rp "aws_access_key_id: " ACCESS_KEY_ID
read -rsp "aws_secret_access_key (no se muestra en pantalla): " SECRET_ACCESS_KEY
echo
read -rsp "aws_session_token (no se muestra en pantalla): " SESSION_TOKEN
echo

aws configure set aws_access_key_id "$ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY"
aws configure set aws_session_token "$SESSION_TOKEN"
aws configure set region us-east-1

echo
echo "Credenciales configuradas. Verificando..."
aws sts get-caller-identity

echo
echo "=================================================================="
echo " RECORDATORIO: estas credenciales tambien deben actualizarse en"
echo " GitHub -> Settings -> Secrets and variables -> Actions:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - AWS_SESSION_TOKEN"
echo " De lo contrario el pipeline de CI/CD fallara al autenticarse."
echo "=================================================================="
