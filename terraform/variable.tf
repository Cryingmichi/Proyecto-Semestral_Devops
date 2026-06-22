variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "innovatech"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_public_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_private_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_public_b_cidr" {
  description = "CIDR de la segunda subred publica (requerida por el Load Balancer en otra AZ)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Segunda Availability Zone, requerida por el Load Balancer"
  type        = string
  default     = "us-east-1b"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "innovatech-eks"
}
