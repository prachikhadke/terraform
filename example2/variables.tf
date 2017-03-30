
variable "chef_server_ssh_public_key" {}

variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "us-east-1"
}

variable "aws_availability_zone" {
    description = "EC2 Availability Zone for the Region for the VPC"
    default = "us-east-1a"
}

variable "amis" {
    description = "AMIs by region"
    default = {
        us-east-1 = "ami-6d1c2007"
    }
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.0.1.0/24"
}
