variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "innovatech"
}

variable "db_user" {
  type    = string
  default = "root"
}

variable "db_password" {
  type    = string
  default = "root"
}

variable "db_name" {
  type    = string
  default = "innovatech_db"
}

variable "key_pair_name" {
  type        = string
  default     = "vockey"
  description = "Nombre de la llave SSH para la instancia EC2 (por defecto vockey en AWS Academy)"
}