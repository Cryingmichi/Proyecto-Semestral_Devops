# Tarea ECS para MySQL. No tiene Target Group en el ALB porque no debe
# ser accesible publicamente: solo se descubre via Service Discovery
# (mysql.innovatech.local) y solo los backends pueden alcanzar su puerto 3306.

resource "aws_ecs_task_definition" "mysql" {
  family                   = "${var.project_name}-mysql"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name  = "mysql"
      image = "mysql:8"
      portMappings = [
        { containerPort = 3306, protocol = "tcp" }
      ]
      environment = [
        { name = "MYSQL_DATABASE", value = "innovatech_db" }
      ]
      secrets = [
        {
          name      = "MYSQL_ROOT_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-mysql"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "mysql"
        }
      }
    }
  ])

  tags = {
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "mysql" {
  name              = "/ecs/${var.project_name}-mysql"
  retention_in_days = 7

  tags = {
    Project = var.project_name
  }
}

resource "aws_ecs_service" "mysql" {
  name            = "mysql-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.mysql.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_mysql.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mysql.arn
  }

  tags = {
    Project = var.project_name
  }
}
