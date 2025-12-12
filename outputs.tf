output "ec2_public_ip" {
  description = "IP pública de la instancia Hola desde Terraform"
  value       = aws_instance.hola_terraform.public_ip
}

output "url_hola_terraform" {
  description = "URL para probar Hola desde Terraform"
  value       = "http://${aws_instance.hola_terraform.public_ip}"
}
