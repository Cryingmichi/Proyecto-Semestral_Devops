output "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del control plane de EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "configure_kubectl" {
  description = "Comando para conectar kubectl al cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
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
