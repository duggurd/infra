variable "alphavantage_api_key" {
  description = "API key for Alpha Vantage"
  type        = string
  sensitive   = true
}

variable "sqlserver_password" {
  description = "Password for the SQL Server"
  type        = string
  sensitive   = true
}

resource "aws_secretsmanager_secret" "sqlserver_password" {
    name = "sqlserver_password"
    description = "Password for the SQL Server"
    recovery_window_in_days = 0
    tags = {
        Name = "sqlserver"
    }
}

resource "aws_secretsmanager_secret" "alphavantage" {
    name = "alphavantage"
    description = "API key for Alpha Vantage"
    recovery_window_in_days = 0
    tags = {
        Name = "alphavantage"
    }
}

resource "aws_secretsmanager_secret_version" "alphavantage" {
    secret_id     = aws_secretsmanager_secret.alphavantage.id
    secret_string = var.alphavantage_api_key
}

resource "aws_secretsmanager_secret_version" "sqlserver_password" {
    secret_id     = aws_secretsmanager_secret.sqlserver_password.id
    secret_string = var.sqlserver_password
}