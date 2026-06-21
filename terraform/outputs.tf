output "alb_dns_name" {
  description = "DNS publico del Application Load Balancer (unico punto de entrada de la aplicacion)"
  value       = aws_lb.main.dns_name
}

output "app_url" {
  description = "URL publica del frontend"
  value       = "http://${aws_lb.main.dns_name}"
}

output "api_despachos_url" {
  description = "URL publica de la API de Despachos (via ALB)"
  value       = "http://${aws_lb.main.dns_name}/api/despachos"
}

output "api_ventas_url" {
  description = "URL publica de la API de Ventas (via ALB)"
  value       = "http://${aws_lb.main.dns_name}/api/ventas"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.repo_frontend.repository_url
}

output "ecr_backend_despachos_url" {
  value = aws_ecr_repository.repo_despachos.repository_url
}

output "ecr_backend_ventas_url" {
  value = aws_ecr_repository.repo_ventas.repository_url
}