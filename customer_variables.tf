variable "environment_customer" {
  description = "The environment of the customer network"
  default     = "customer"
}

variable "customer_ami" {
  description = "The ami of the EC2 instances in the customer network"
  default     = "ami-0f9fe1d9214628296"
}

variable "customer_instance_type" {
  description = "The type of the EC2 instance in the customer network"
  default     = "t2.micro"
}

variable "customer_vpc_cidr" {
  description = "The CIDR of the VPC in the customer network"
  default     = "192.168.0.0/16"
}

variable "customer_subnet_cidr" {
  description = "The CIDR of the subnet in the customer network"
  default     = "192.168.0.0/24"
}

variable "customer_subnet_az" {
  description = "The availability zone of the customer network"
  default     = "ap-northeast-1a"
}