data "archive_file" "alphavantage" {
  type        = "zip"
  source_dir = "${path.module}/alphavantage"
  output_path = "${path.module}/alphavantage.zip"
}

data "archive_file" "alphavantage_packages" {
  type        = "zip"
  source_dir = "${path.module}/alphavantage_packages"
  output_path = "${path.module}/alphavantage_packages.zip"
}

resource "aws_lambda_function" "alphavantage_stock_api" {
  filename      = data.archive_file.alphavantage.output_path
  function_name = "alphavantage_stock_api"
  handler       = "alphavantage.lambda_handler"
  role          = aws_iam_role.lambda_thing.arn
  runtime       = "python3.11"
  timeout       = 3

  layers = [ aws_lambda_layer_version.alphavantage_packages.arn ]

  source_code_hash = filebase64sha256(data.archive_file.alphavantage.output_path)

  vpc_config {
    subnet_ids         = [aws_subnet.subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_layer_version" "alphavantage_packages" {
  filename = data.archive_file.alphavantage_packages.output_path
  layer_name = "alphavantage_packages"
  compatible_runtimes = ["python3.11"]
  source_code_hash = filebase64sha256(data.archive_file.alphavantage_packages.output_path)
}