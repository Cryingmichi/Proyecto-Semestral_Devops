terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Registro ECR para el Frontend
resource "aws_ecr_repository" "frontend" {
  name         = "${var.nombre_proyecto}-frontend"
  force_delete = true
}

# Registro ECR para el Backend de Despachos
resource "aws_ecr_repository" "backend_despachos" {
  name         = "${var.nombre_proyecto}-backend-despachos"
  force_delete = true
}

# Registro ECR para el Backend de Ventas
resource "aws_ecr_repository" "backend_ventas" {
  name         = "${var.nombre_proyecto}-backend-ventas"
  force_delete = true
}