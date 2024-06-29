variable "environment_aws" {
  description = "The environment of the AWS network"
  default     = "aws"
}

variable "aws_ami" {
  description = "The ami of the EC2 instances in the AWS network"
  default     = "ami-081a36454cdf357cb"
}

variable "aws_instance_type" {
  description = "The type of the EC2 instance in the AWS network"
  default     = "t2.micro"
}

variable "aws_vpc_cidr" {
  description = "The CIDR of the VPC in the AWS network"
  default     = "10.0.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "The CIDR of the subnet in the AWS network"
  default     = "10.0.0.0/24"
}

variable "aws_subnet_az" {
  description = "The availability zone of the AWS network"
  default     = "ap-northeast-2a"
}