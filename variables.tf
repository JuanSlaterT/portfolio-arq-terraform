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
  description = "Tamano del disco principal en GB"
  type        = number
  default     = 20
}

variable "dockerhub_username" {
  description = "Usuario u organizacion de Docker Hub que publica las imagenes"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.dockerhub_username))
    error_message = "dockerhub_username debe ser un usuario u organizacion valido de Docker Hub."
  }
}

variable "bff_version" {
  description = "Etiqueta de la imagen Docker del BFF"
  type        = string

  validation {
    condition     = length(trimspace(var.bff_version)) > 0
    error_message = "bff_version no puede estar vacia."
  }
}

variable "language_version" {
  description = "Etiqueta de la imagen Docker del servicio de lenguajes"
  type        = string

  validation {
    condition     = length(trimspace(var.language_version)) > 0
    error_message = "language_version no puede estar vacia."
  }
}

variable "domain_name" {
  description = "Dominio publico usado por Nginx y Let's Encrypt"
  type        = string

  validation {
    condition     = length(var.domain_name) <= 253 && can(regex("^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,63}$", var.domain_name))
    error_message = "domain_name debe ser un nombre DNS completo valido."
  }
}

variable "deployment_base_dir" {
  description = "Directorio de la instancia donde se instala la aplicacion"
  type        = string
  default     = "/opt/portfolio"

  validation {
    condition     = startswith(var.deployment_base_dir, "/") && var.deployment_base_dir != "/"
    error_message = "deployment_base_dir debe ser una ruta absoluta distinta de /."
  }
}

variable "docker_compose_version" {
  description = "Version del plugin Docker Compose que instala el bootstrap"
  type        = string
  default     = "v5.1.4"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.docker_compose_version))
    error_message = "docker_compose_version debe tener el formato vMAJOR.MINOR.PATCH."
  }
}

variable "bff_upstream_url" {
  description = "URL interna de Docker que Nginx usa para conectarse al BFF"
  type        = string

  validation {
    condition     = can(regex("^https?://[A-Za-z0-9][A-Za-z0-9._-]*(?::[1-9][0-9]{0,4})?$", var.bff_upstream_url))
    error_message = "bff_upstream_url debe ser una URL HTTP(S) interna, por ejemplo http://bff:8080."
  }
}

variable "bff_environment" {
  description = "Variables de entorno inyectadas en el contenedor BFF"
  type        = map(string)
  sensitive   = true

  validation {
    condition = alltrue([
      for name, value in var.bff_environment :
      can(regex("^[A-Za-z_][A-Za-z0-9_]*$", name)) && length(value) > 0
    ])
    error_message = "Cada nombre debe ser una variable de entorno valida y su valor no puede estar vacio."
  }
}


variable "stats_version" {
  description = "Etiqueta de la imagen Docker del servicio de estadísticas"
  type        = string

  validation {
    condition     = length(trimspace(var.stats_version)) > 0
    error_message = "stats_version no puede estar vacia."
  }
}


variable "stats_environment" {
  description = "Variables de entorno inyectadas en stats-service"
  type        = map(string)
  sensitive   = true

  validation {
    condition = alltrue([
      for name, value in var.stats_environment :
      can(regex("^[A-Za-z_][A-Za-z0-9_]*$", name)) && length(value) > 0
    ])
    error_message = "Cada variable de stats-service debe tener un nombre valido y un valor no vacio."
  }
}