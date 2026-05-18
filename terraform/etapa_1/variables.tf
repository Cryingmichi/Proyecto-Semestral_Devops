variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Región de AWS para desplegar los recursos"
}

variable "nombre_proyecto" {
  type        = string
  default     = "innovatech"
  description = "Nombre base que se usará para identificar los repositorios"
}