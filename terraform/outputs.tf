output "ec2_frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "ec2_backend_private_ip" {
  value = aws_instance.backend.private_ip
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

output "app_url" {
  value = "http://${aws_instance.frontend.public_ip}"
}