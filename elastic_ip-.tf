resource "aws_eip" "portfolio" {

  instance = aws_instance.portfolio.id
  domain   = "vpc"

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = "${var.project_name}-eip"
  }
}