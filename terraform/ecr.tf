resource "aws_ecr_repository" "repo_frontend" {
  name                 = "innovatech-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "innovatech-frontend"
    Project = var.project_name
  }
}

resource "aws_ecr_repository" "repo_despachos" {
  name                 = "innovatech-backend-despachos"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "innovatech-backend-despachos"
    Project = var.project_name
  }
}

resource "aws_ecr_repository" "repo_ventas" {
  name                 = "innovatech-backend-ventas"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "innovatech-backend-ventas"
    Project = var.project_name
  }
}