# VPC
resource "aws_vpc" "customer_vpc" {
  provider   = aws.japan
  cidr_block = var.customer_vpc_cidr

  tags = {
    Name = "${var.project_name}-${var.environment_customer}-vpc"
  }
}

# Subnet
resource "aws_subnet" "customer_subnet" {
  provider          = aws.japan
  vpc_id            = aws_vpc.customer_vpc.id
  cidr_block        = var.customer_subnet_cidr
  availability_zone = var.customer_subnet_az

  tags = {
    Name = "${var.project_name}-${var.environment_customer}-subnet"
  }
}

# Security Group
resource "aws_security_group" "customer_sg" {
  provider = aws.japan
  vpc_id   = aws_vpc.customer_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["3.112.23.0/29"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.aws_vpc.cidr_block]
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
resource "aws_instance" "customer_instance" {
  provider      = aws.japan
  ami           = var.customer_ami
  instance_type = var.customer_instance_type
  subnet_id     = aws_subnet.customer_subnet.id

  vpc_security_group_ids = [aws_security_group.customer_sg.id]

  source_dest_check = false

  tags = {
    Name = "${var.project_name}-${var.environment_customer}-instance"
  }
}

# Elastic IP
resource "aws_eip" "customer_eip" {
  provider = aws.japan
  instance = aws_instance.customer_instance.id

  tags = {
    Name = "${var.project_name}-${var.environment_customer}-eip"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "customer_igw" {
  provider = aws.japan
  vpc_id   = aws_vpc.customer_vpc.id

  tags = {
    Name = "${var.project_name}-${var.environment_customer}-igw"
  }
}

# Route Table
resource "aws_route_table" "customer_route_table" {
  provider = aws.japan
  vpc_id   = aws_vpc.customer_vpc.id

  route {
    cidr_block = var.customer_vpc_cidr
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.customer_igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment_customer}-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "customer_route_table_association" {
  provider       = aws.japan
  subnet_id      = aws_subnet.customer_subnet.id
  route_table_id = aws_route_table.customer_route_table.id

  depends_on = [aws_route_table.customer_route_table]

}
