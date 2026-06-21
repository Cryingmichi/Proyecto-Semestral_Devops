# Log Groups en CloudWatch para poder revisar logs de cada servicio
# (kubectl logs no aplica en ECS; aquí el equivalente es CloudWatch Logs).

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 7

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "despachos" {
  name              = "/ecs/${var.project_name}-backend-despachos"
  retention_in_days = 7

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "ventas" {
  name              = "/ecs/${var.project_name}-backend-ventas"
  retention_in_days = 7

  tags = {
    Project = var.project_name
  }
}
