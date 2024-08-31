resource "aws_db_instance" "example" {
  allocated_storage     = 20
  max_allocated_storage = 0
  engine               = "sqlserver-ex"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = aws_secretsmanager_secret_version.sqlserver_password.secret_string
  publicly_accessible  = false
  skip_final_snapshot  = true
}