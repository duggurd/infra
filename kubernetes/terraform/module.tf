terraform {
    required_providers {
        docker = {
          source  = "kreuzwerker/docker"
          version = "3.0.2"
        }
    }
}

variable "storage_class_name" {
  description = "The name of the storage class to use for the PVC"
  type        = string
}

variable "postgres_password" {
  type = string
  default = "123"
}

variable "registry_url" {
  type = string
  description = "registry url"
  default = "localhost:5000"
}