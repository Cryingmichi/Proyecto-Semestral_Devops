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

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  type    = string
  default = "ami-0c02fb55956c7d316"
}

variable "key_name" {
  type    = string
  default = "vockey"
}

variable "my_ip" {
  type    = string
  default = "0.0.0.0/0"
}