# Security Groups para la arquitectura ECS/Fargate.
# Principio: el único punto de entrada público es el ALB (puerto 80).
# El servicio frontend solo recibe tráfico del ALB.
# Los servicios backend (despachos, ventas) solo reciben tráfico
# desde el Security Group de las tareas del frontend.

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security Group del Application Load Balancer (unico punto de entrada publico)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-alb"
    Project = var.project_name
  }
}

resource "aws_security_group" "ecs_frontend" {
  name        = "${var.project_name}-sg-ecs-frontend"
  description = "Security Group tareas ECS Frontend - solo recibe trafico del ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-ecs-frontend"
    Project = var.project_name
  }
}

resource "aws_security_group" "ecs_despachos" {
  name        = "${var.project_name}-sg-ecs-despachos"
  description = "Security Group tarea ECS Backend Despachos - solo interno"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API Despachos desde el ALB"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-ecs-despachos"
    Project = var.project_name
  }
}

resource "aws_security_group" "ecs_ventas" {
  name        = "${var.project_name}-sg-ecs-ventas"
  description = "Security Group tarea ECS Backend Ventas - solo interno"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API Ventas desde el ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-ecs-ventas"
    Project = var.project_name
  }
}

resource "aws_security_group" "ecs_mysql" {
  name        = "${var.project_name}-sg-ecs-mysql"
  description = "Security Group tarea ECS MySQL - solo accesible desde los backends"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde Backend Despachos"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_despachos.id]
  }

  ingress {
    description     = "MySQL desde Backend Ventas"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_ventas.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-ecs-mysql"
    Project = var.project_name
  }
}
