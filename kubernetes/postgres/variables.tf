variable "postgres_password" {
    type = string
    sensitive = true
}

variable "app_selector" {
  type = string
  default = "postgres"
}

variable "pvc_name" {
    type = string
    default = "postgres-pvc"
  
}