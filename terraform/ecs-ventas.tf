# Tarea ECS para el backend Ventas. No es accesible publicamente:
# solo recibe trafico desde el ALB (vía el target group asociado),
# segun la regla de path /api/ventas* del listener.

resource "aws_ecs_task_definition" "ventas" {
  family                   = "${var.project_name}-backend-ventas"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend-ventas"
      image = "${aws_ecr_repository.repo_ventas.repository_url}:latest"
      portMappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
      environment = [
        { name = "DB_ENDPOINT", value = "mysql.${aws_service_discovery_private_dns_namespace.main.name}" },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_NAME", value = "innovatech_db" },
        { name = "DB_USERNAME", value = "root" }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ventas.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ventas"
        }
      }
    }
  ])

  tags = {
    Project = var.project_name
  }
}

resource "aws_ecs_service" "ventas" {
  name            = "ventas-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ventas.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_ventas.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ventas.arn
    container_name    = "backend-ventas"
    container_port    = 8080
  }

  depends_on = [aws_lb_listener.http, aws_ecs_service.mysql]

  tags = {
    Project = var.project_name
  }
}
