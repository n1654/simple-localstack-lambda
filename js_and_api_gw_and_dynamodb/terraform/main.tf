variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {}

provider "aws" {
  access_key                  = var.aws_access_key
  secret_key                  = var.aws_secret_key
  region                      = var.region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  endpoints {
    dynamodb   = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    iam        = "http://localhost:4566"
    apigateway = "http://localhost:4566"
  }
}

resource "aws_dynamodb_table" "http-crud-tutorial-items" {
  name           = "http-crud-tutorial-items"
  read_capacity  = 10
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_iam_role" "http-crud-tutorial-role" {
  name = "http-crud-tutorial-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      },
      {
      			"Effect": "Allow",
      			"Action": [
      				"dynamodb:BatchGetItem",
      				"dynamodb:GetItem",
      				"dynamodb:Query",
      				"dynamodb:Scan",
      				"dynamodb:BatchWriteItem",
      				"dynamodb:PutItem",
      				"dynamodb:UpdateItem"
      			],
      			"Resource": "arn:aws:dynamodb:ap-southeast-2:000000000000:table/http-crud-tutorial-items"
      		}
    ]
  })

  tags = {
    "Terraform" : "true"
  }
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "aws-lambda-basic-policy-attach" {
  role       = aws_iam_role.http-crud-tutorial-role.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

resource "aws_lambda_function" "lambda_handler" {
  filename      = "../my-deployment-package.zip"
  function_name = "lambda_handler"
  role          = aws_iam_role.http-crud-tutorial-role.name
  handler       = "http-crud-tutorial-function.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("../my-deployment-package.zip")

  runtime = "nodejs12.x"
}


resource "aws_api_gateway_rest_api" "http-crud-tutorial-api" {
  name = "http-crud-tutorial-api"
}

resource "aws_api_gateway_resource" "items" {
  parent_id   = aws_api_gateway_rest_api.http-crud-tutorial-api.root_resource_id
  path_part   = "items"
  rest_api_id = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_resource" "items-id" {
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{id}"
  rest_api_id = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_method" "items-get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.items.id
  rest_api_id   = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_method" "items-put" {
  authorization = "NONE"
  http_method   = "PUT"
  resource_id   = aws_api_gateway_resource.items.id
  rest_api_id   = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_method" "items-id-get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.items-id.id
  rest_api_id   = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_method" "items-id-delete" {
  authorization = "NONE"
  http_method   = "DELETE"
  resource_id   = aws_api_gateway_resource.items-id.id
  rest_api_id   = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_integration" "items-get-integration" {
  http_method             = aws_api_gateway_method.items-get.http_method
  resource_id             = aws_api_gateway_resource.items.id
  rest_api_id             = aws_api_gateway_rest_api.http-crud-tutorial-api.id
  type                    = "AWS_PROXY"
  integration_http_method = "GET"
  uri                     = aws_lambda_function.lambda_handler.invoke_arn
}

resource "aws_api_gateway_integration" "items-put-integration" {
  http_method             = aws_api_gateway_method.items-put.http_method
  resource_id             = aws_api_gateway_resource.items.id
  rest_api_id             = aws_api_gateway_rest_api.http-crud-tutorial-api.id
  type                    = "AWS_PROXY"
  integration_http_method = "PUT"
  uri                     = aws_lambda_function.lambda_handler.invoke_arn
}

resource "aws_api_gateway_integration" "items-id-get-integration" {
  http_method             = aws_api_gateway_method.items-id-get.http_method
  resource_id             = aws_api_gateway_resource.items-id.id
  rest_api_id             = aws_api_gateway_rest_api.http-crud-tutorial-api.id
  type                    = "AWS_PROXY"
  integration_http_method = "GET"
  uri                     = aws_lambda_function.lambda_handler.invoke_arn
}

resource "aws_api_gateway_integration" "items-id-delete-integration" {
  http_method             = aws_api_gateway_method.items-id-delete.http_method
  resource_id             = aws_api_gateway_resource.items-id.id
  rest_api_id             = aws_api_gateway_rest_api.http-crud-tutorial-api.id
  type                    = "AWS_PROXY"
  integration_http_method = "DELETE"
  uri                     = aws_lambda_function.lambda_handler.invoke_arn
}


resource "aws_api_gateway_deployment" "http-crud-tutorial-dpl" {
  rest_api_id = aws_api_gateway_rest_api.http-crud-tutorial-api.id
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.http-crud-tutorial-dpl.id
  rest_api_id   = aws_api_gateway_rest_api.http-crud-tutorial-api.id
  stage_name    = "dev"
}
