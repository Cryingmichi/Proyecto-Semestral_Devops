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

output "mysql_public_ip" {
  value       = aws_instance.db.public_ip
  description = "IP pública del servidor EC2 MySQL"
}

output "backend_despachos_public_ip" {
  value       = aws_instance.backend_despachos.public_ip
  description = "IP pública del servidor EC2 para Backend Despachos (Puerto 8080)"
}

output "backend_ventas_public_ip" {
  value       = aws_instance.backend_ventas.public_ip
  description = "IP pública del servidor EC2 para Backend Ventas (Puerto 8081)"
}

output "frontend_public_ip" {
  value       = aws_instance.frontend.public_ip
  description = "IP pública del servidor EC2 para el Frontend (Puerto 80)"
}