# Application Load Balancer: unico punto de entrada publico del sistema.
# - Listener puerto 80 -> por defecto enruta al frontend
# - Reglas de path /api/despachos/* y /api/ventas/* -> enrutan a cada backend
# Esto cumple el requisito de IE2 (balanceo + comunicacion Front->Back
# vía ALB) y mantiene el principio de que solo se entra por una IP/DNS publica.

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

# --- Target Group: Frontend ---
resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-tg-frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # requerido por Fargate

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = {
    Project = var.project_name
  }
}

# --- Target Group: Backend Despachos ---
resource "aws_lb_target_group" "despachos" {
  name        = "${var.project_name}-tg-despachos"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = {
    Project = var.project_name
  }
}

# --- Target Group: Backend Ventas ---
resource "aws_lb_target_group" "ventas" {
  name        = "${var.project_name}-tg-ventas"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = {
    Project = var.project_name
  }
}

# --- Listener principal (puerto 80) ---
# Por defecto enruta al frontend; las reglas de abajo desvían
# el trafico de API hacia cada backend segun el path.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "despachos" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.despachos.arn
  }

  condition {
    path_pattern {
      values = ["/api/despachos*"]
    }
  }
}

resource "aws_lb_listener_rule" "ventas" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ventas.arn
  }

  condition {
    path_pattern {
      values = ["/api/ventas*"]
    }
  }
}
