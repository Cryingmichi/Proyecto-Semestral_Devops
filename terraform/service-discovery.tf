# Service Discovery (AWS Cloud Map): permite que los backends
# encuentren al servicio MySQL por DNS interno dentro de la VPC,
# sin necesidad de IPs fijas ni de exponer MySQL al exterior.
# Ejemplo de DNS resultante: mysql.innovatech.local

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "${var.project_name}.local"
  vpc  = aws_vpc.main.id

  tags = {
    Project = var.project_name
  }
}

resource "aws_service_discovery_service" "mysql" {
  name = "mysql"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
