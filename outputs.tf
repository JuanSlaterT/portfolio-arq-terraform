output "instance_id" {
  value = aws_instance.portfolio.id
}

output "public_ip" {
  value = aws_eip.portfolio.public_ip
}

output "private_ip" {
  value = aws_instance.portfolio.private_ip
}

output "https_url" {
  value = "https://${aws_eip.portfolio.public_ip}"
}