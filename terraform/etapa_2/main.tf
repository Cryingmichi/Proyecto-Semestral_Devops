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

############################
# CONFIGURACIÓN DE RED (VPC)
############################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

############################
# SECURITY GROUP Y REGLAS
############################

resource "aws_security_group" "main" {
  name   = "${var.project_name}-sg-v2"  # Se cambió el nombre para evitar conflictos residuales
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "mysql_internal" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main.id
  source_security_group_id = aws_security_group.main.id
}

############################
# DATA EXTERNA (REPOSITORIOS ECR ETAPA 1)
############################

data "aws_ecr_repository" "frontend" {
  name = "${var.project_name}-frontend"
}

data "aws_ecr_repository" "backend_despachos" {
  name = "${var.project_name}-backend-despachos"
}

data "aws_ecr_repository" "backend_ventas" {
  name = "${var.project_name}-backend-ventas"
}

data "aws_iam_role" "lab" {
  name = "LabRole"
}

############################
# CONFIGURACIÓN DE AMIs
############################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

############################
# INSTANCIA EC2 - MYSQL
############################

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    until docker info > /dev/null 2>&1; do
      echo "Esperando Docker..."
      sleep 3
    done

    docker run -d \
    --name mysql \
    -e MYSQL_ROOT_PASSWORD=${var.db_password} \
    -e MYSQL_DATABASE=${var.db_name} \
    -e MYSQL_ROOT_HOST=% \
    -p 3306:3306 \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    mysql:8-oracle \
    --bind-address=0.0.0.0 \
    --performance-schema=OFF
  EOF

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

############################
# INSTANCIA EC2 - BACKEND DESPACHOS
############################

resource "aws_instance" "backend_despachos" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = "LabInstanceProfile" # Perfil requerido en AWS Academy para descargar de ECR

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    until docker info > /dev/null 2>&1; do
      sleep 3
    done

    # Autenticarse en ECR de forma local usando el rol asignado a la instancia
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_ecr_repository.backend_despachos.repository_url}

    # Descargar y correr el contenedor de Despachos en el puerto 8080
    docker run -d \
      --name backend-despachos \
      -p 8080:8080 \
      -e DB_HOST=${aws_instance.db.private_ip} \
      -e SPRING_DATASOURCE_URL=jdbc:mysql://${aws_instance.db.private_ip}:3306/${var.db_name} \
      -e SPRING_DATASOURCE_USERNAME=${var.db_user} \
      -e SPRING_DATASOURCE_PASSWORD=${var.db_password} \
      ${data.aws_ecr_repository.backend_despachos.repository_url}:latest
  EOF

  tags = {
    Name = "${var.project_name}-backend-despachos"
  }
}

############################
# INSTANCIA EC2 - BACKEND VENTAS
############################

resource "aws_instance" "backend_ventas" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = "LabInstanceProfile"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    until docker info > /dev/null 2>&1; do
      sleep 3
    done

    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_ecr_repository.backend_ventas.repository_url}

    # Descargar y correr el contenedor de Ventas en el puerto 8081
    docker run -d \
      --name backend-ventas \
      -p 8081:8081 \
      -e DB_HOST=${aws_instance.db.private_ip} \
      -e SPRING_DATASOURCE_URL=jdbc:mysql://${aws_instance.db.private_ip}:3306/${var.db_name} \
      -e SPRING_DATASOURCE_USERNAME=${var.db_user} \
      -e SPRING_DATASOURCE_PASSWORD=${var.db_password} \
      ${data.aws_ecr_repository.backend_ventas.repository_url}:latest
  EOF

  tags = {
    Name = "${var.project_name}-backend-ventas"
  }
}

############################
# INSTANCIA EC2 - FRONTEND
############################

resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = "LabInstanceProfile"

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    until docker info > /dev/null 2>&1; do
      sleep 3
    done

    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_ecr_repository.frontend.repository_url}

    # Descargar y correr el contenedor del Frontend en el puerto 80
    docker run -d \
      --name frontend \
      -p 80:80 \
      ${data.aws_ecr_repository.frontend.repository_url}:latest
  EOF

  tags = {
    Name = "${var.project_name}-frontend"
  }
}