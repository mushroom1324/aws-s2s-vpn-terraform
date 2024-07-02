# VPC
resource "aws_vpc" "aws_vpc" {
  provider   = aws.seoul
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-vpc"
  }
}

# Subnet
resource "aws_subnet" "aws_subnet" {
  provider          = aws.seoul
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = var.aws_subnet_az

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-subnet"
  }
}

# Security Group
resource "aws_security_group" "aws_sg" {
  provider = aws.seoul
  vpc_id   = aws_vpc.aws_vpc.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.customer_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-sg"
  }
}

# EC2 Instance
resource "aws_instance" "aws_instance" {
  provider      = aws.seoul
  ami           = var.aws_ami
  instance_type = var.aws_instance_type
  subnet_id     = aws_subnet.aws_subnet.id

  vpc_security_group_ids = [aws_security_group.aws_sg.id]

  source_dest_check = false

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-instance"
  }
}

# Route Table
resource "aws_route_table" "aws_route_table" {
  provider = aws.seoul
  vpc_id   = aws_vpc.aws_vpc.id

  route {
    cidr_block = var.aws_vpc_cidr
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_vpn_gateway.aws_vpn_gateway.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "aws_route_table_association" {
  provider       = aws.seoul
  subnet_id      = aws_subnet.aws_subnet.id
  route_table_id = aws_route_table.aws_route_table.id

  depends_on = [aws_route_table.aws_route_table]

}

# Virtual Private Gateway
resource "aws_vpn_gateway" "aws_vpn_gateway" {
  provider = aws.seoul
  vpc_id   = aws_vpc.aws_vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-vgw"
  }
}

# Customer Gateway
resource "aws_customer_gateway" "aws_customer_gateway" {
  provider   = aws.seoul
  bgp_asn    = "65000"
  ip_address = aws_eip.customer_eip.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-cgw"
  }
}

# Site to Site VPN Connection
resource "aws_vpn_connection" "aws_vpn_connection" {
  provider            = aws.seoul
  vpn_gateway_id      = aws_vpn_gateway.aws_vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.aws_customer_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true

  local_ipv4_network_cidr  = aws_vpc.customer_vpc.cidr_block
  remote_ipv4_network_cidr = aws_vpc.aws_vpc.cidr_block

  tags = {
    Name = "${var.project_name}-${var.environment_aws}-vpn"
  }
}

# VPN Connection Route
resource "aws_vpn_connection_route" "aws_vpn_connection_route" {
  provider               = aws.seoul
  destination_cidr_block = aws_vpc.customer_vpc.cidr_block
  vpn_connection_id      = aws_vpn_connection.aws_vpn_connection.id
}