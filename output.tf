output "api_endpoint" {
  description = "Base URL of the API Gateway."
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "encrypt_url" {
  description = "Full POST endpoint for encrypting values."
  value       = "${aws_api_gateway_stage.prod.invoke_url}/encrypt"
}

output "curl_example" {
  description = "Example curl command to encrypt credit card values."
  value       = <<-EOT
    curl -X POST ${aws_api_gateway_stage.prod.invoke_url}/encrypt \
      -H "Content-Type: application/json" \
      -d '{"cryptId":"cc","values":["1111-1111-1111-1111","2222-2222-2222-2222"]}'
  EOT
}
