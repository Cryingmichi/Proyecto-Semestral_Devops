# Autoscaling (IE3): Target Tracking basado en uso de CPU.
# Umbral elegido: 50% de CPU promedio.
# Justificacion: 50% deja margen para absorber picos de trafico sin
# saturar la tarea antes de que se complete el scale-out (que toma
# uno o dos minutos en Fargate), evitando degradar tiempos de respuesta,
# y evita el extremo opuesto de escalar de forma innecesaria con cargas
# bajas (lo que ocurriria con un umbral muy bajo, ej. 20%).

# --- Frontend ---
resource "aws_appautoscaling_target" "frontend" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "${var.project_name}-frontend-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# --- Backend Despachos ---
resource "aws_appautoscaling_target" "despachos" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.despachos.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "despachos_cpu" {
  name               = "${var.project_name}-despachos-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.despachos.resource_id
  scalable_dimension = aws_appautoscaling_target.despachos.scalable_dimension
  service_namespace  = aws_appautoscaling_target.despachos.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# --- Backend Ventas ---
resource "aws_appautoscaling_target" "ventas" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.ventas.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ventas_cpu" {
  name               = "${var.project_name}-ventas-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ventas.resource_id
  scalable_dimension = aws_appautoscaling_target.ventas.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ventas.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 50
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
