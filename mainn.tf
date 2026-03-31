provider "aws" {
  region = "ap-south-1"
}

resource "aws_dynamodb_table" "users" {
  name         = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
}
#-------------------------------------


resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({

    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "Register_user" {
  function_name = "RegisterUser"
  runtime       = "python3.11"
  handler       = "lambda_fun.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = "lambda_fun.zip"
  source_code_hash = filebase64sha256("lambda_fun.zip")
}
 #----------------------


resource "aws_apigatewayv2_api" "api" {
  name          = "user-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  integration_uri = aws_lambda_function.Register_user.invoke_arn
}

resource "aws_apigatewayv2_route" "post_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /register"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Register_user.function_name
  principal     = "apigateway.amazonaws.com"
}

#---------------------------

resource "aws_lambda_function" "get_user" {
  function_name = "getUsers"
  runtime       = "python3.11"
  handler       = "get_user.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = "get_user.zip"
  source_code_hash = filebase64sha256("get_user.zip")
}

resource "aws_apigatewayv2_integration" "get_users_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  integration_uri = aws_lambda_function.get_user.invoke_arn
}

resource "aws_apigatewayv2_route" "get_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /users"

  target = "integrations/${aws_apigatewayv2_integration.get_users_integration.id}"
}

resource "aws_lambda_permission" "api_permission_get" {
  statement_id  = "AllowAPIGatewayInvokeGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user.function_name
  principal     = "apigateway.amazonaws.com"

}