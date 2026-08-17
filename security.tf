resource "aws_security_group" "portfolio" {
  name        = "${var.project_name}-sg"
  description = "Security Group for Portfolio EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.portfolio.id

  description = "Allow HTTP for Let's Encrypt"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.portfolio.id

  description = "Allow HTTPS"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.portfolio.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}