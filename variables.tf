variable "prefix" {
  description = "Short identifier prepended to every API Gateway resource name (e.g. \"poc10\")."
  type        = string
}

variable "lambda_function_name" {
  description = "Exact name of the existing Lambda function to invoke (e.g. \"demo-10-cryptid-test\")."
  type        = string
}

variable "aws_region" {
  description = "AWS region where the Lambda and API Gateway are deployed (e.g. \"us-east-1\", \"eu-west-1\")."
  type        = string
}
