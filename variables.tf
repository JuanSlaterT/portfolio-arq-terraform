variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "portfolio"
}

variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Tamaño del disco principal en GB"
  type        = number
  default     = 20
}



variable "dockerhub_username" {
  type = string
}

variable "bff_version" {
  type    = string
  default = "latest"
}

variable "language_version" {
  type    = string
  default = "latest"
}

variable "domain_name" {
  type    = string
  default = "_"
}