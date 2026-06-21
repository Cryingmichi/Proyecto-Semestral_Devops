locals {
  user_data_docker = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker git aws-cli
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  EOF
}

resource "aws_instance" "frontend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.user_data_docker

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name    = "${var.project_name}-ec2-frontend"
    Project = var.project_name
  }
}

resource "aws_instance" "backend_despachos" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.backend_despachos.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.user_data_docker

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name    = "${var.project_name}-ec2-backend-despachos"
    Project = var.project_name
  }
}

resource "aws_instance" "backend_ventas" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.backend_ventas.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.user_data_docker

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name    = "${var.project_name}-ec2-backend-ventas"
    Project = var.project_name
  }
}