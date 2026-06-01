provider "aws" {
  region = var.aws_region
}

# ── Lookup existing Lambda deployed by TF-lambda ───────────────────────────────

data "aws_lambda_function" "cryptid_encrypt" {
  function_name = var.lambda_function_name
}

# ── REST API (v1) ──────────────────────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "cryptid_api" {
  name = "${var.prefix}-cryptid-api"
}

resource "aws_api_gateway_resource" "encrypt" {
  rest_api_id = aws_api_gateway_rest_api.cryptid_api.id
  parent_id   = aws_api_gateway_rest_api.cryptid_api.root_resource_id
  path_part   = "encrypt"
}

resource "aws_api_gateway_method" "post_encrypt" {
  rest_api_id   = aws_api_gateway_rest_api.cryptid_api.id
  resource_id   = aws_api_gateway_resource.encrypt.id
  http_method   = "POST"
  authorization = "NONE"
}

# ── Lambda integration — body passed directly as the Lambda event ──────────────

resource "aws_api_gateway_integration" "cryptid_encrypt" {
  rest_api_id             = aws_api_gateway_rest_api.cryptid_api.id
  resource_id             = aws_api_gateway_resource.encrypt.id
  http_method             = aws_api_gateway_method.post_encrypt.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = data.aws_lambda_function.cryptid_encrypt.invoke_arn

  request_templates = {
    "application/json" = "$input.json('$')"
  }
}

resource "aws_api_gateway_method_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.cryptid_api.id
  resource_id = aws_api_gateway_resource.encrypt.id
  http_method = aws_api_gateway_method.post_encrypt.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.cryptid_api.id
  resource_id = aws_api_gateway_resource.encrypt.id
  http_method = aws_api_gateway_method.post_encrypt.http_method
  status_code = aws_api_gateway_method_response.ok.status_code

  depends_on = [aws_api_gateway_integration.cryptid_encrypt]
}

# ── Deploy ─────────────────────────────────────────────────────────────────────

resource "aws_api_gateway_deployment" "cryptid_api" {
  rest_api_id = aws_api_gateway_rest_api.cryptid_api.id

  depends_on = [
    aws_api_gateway_integration.cryptid_encrypt,
    aws_api_gateway_integration_response.ok,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.cryptid_api.id
  deployment_id = aws_api_gateway_deployment.cryptid_api.id
  stage_name    = "prod"
}

# ── Allow API Gateway to invoke the Lambda ─────────────────────────────────────

resource "aws_lambda_permission" "apigw_cryptid_encrypt" {
  statement_id  = "AllowAPIGWInvokeCryptidEncrypt"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.cryptid_encrypt.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cryptid_api.execution_arn}/*/POST/encrypt"
}
