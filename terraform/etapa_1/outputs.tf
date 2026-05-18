output "frontend_ecr" {
  value       = aws_ecr_repository.frontend.repository_url
  description = "URL del repositorio ECR para el Frontend"
}

output "backend_despachos_ecr" {
  value       = aws_ecr_repository.backend_despachos.repository_url
  description = "URL del repositorio ECR para Despachos"
}

output "backend_ventas_ecr" {
  value       = aws_ecr_repository.backend_ventas.repository_url
  description = "URL del repositorio ECR para Ventas"
}