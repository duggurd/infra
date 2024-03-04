
resource "aws_iam_role" "lambda_thing" {
  name = "lambda-thing"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_policy" "secrets_manager_policy" {
  name = "secrets_manager_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue",
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda" {
  name = "lambda-policy"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "lambda:*",
          Effect = "Allow",
          Resource = "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_ar_attachment" {
  role       = aws_iam_role.lambda_thing.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attachment" {
  role = aws_iam_role.lambda_thing.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}