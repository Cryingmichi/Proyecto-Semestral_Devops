output "backend_despachos_ecr" {
  value       = data.aws_ecr_repository.backend_despachos.repository_url
  description = "URL del repositorio ECR para el Backend de Despachos"
}

output "backend_ventas_ecr" {
  value       = data.aws_ecr_repository.backend_ventas.repository_url
  description = "URL del repositorio ECR para el Backend de Ventas"
}

output "frontend_ecr" {
  value       = data.aws_ecr_repository.frontend.repository_url
  description = "URL del repositorio ECR para el Frontend"
}

output "mysql_ip" {
  value       = aws_instance.db.public_ip
  description = "IP pública del servidor EC2 MySQL"
}