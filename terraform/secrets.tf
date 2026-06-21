# Gestion de credenciales sensibles (IE5): la contraseña de MySQL
# se almacena en AWS Secrets Manager y se inyecta en las tareas ECS
# via "secrets" (no como variable de entorno en texto plano), tanto
# para el contenedor de MySQL como para los backends que lo consumen.

resource "random_password" "db_password" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/db-credentials"
  description             = "Credenciales de la base de datos MySQL usada por los backends"
  recovery_window_in_days = 0 # permite recrear el secret sin esperar dias en cuentas de laboratorio

  tags = {
    Project = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = "root"
    password = random_password.db_password.result
    database = "innovatech_db"
  })
}
