variable "kubernetes_context" {
    type = string
    description = "active kubernetes context"
    default = "default"
    validation {
        condition = length(var.kubernetes_context) > 0
        error_message = "kubernetes_context must be set"
    }
}

variable "postgres_password" {
    type = string
    description = "postgres password"
    default = "123"
}

variable "docker_host" {
    type = string
    description = "docker host"
    default = "npipe:////.//pipe//docker_engine"
}

variable "registry_url" {
    type = string
    description = "registry url"
    default = "localhost:5000"
}