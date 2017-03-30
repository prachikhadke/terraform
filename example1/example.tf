variable "region" {
  default = "us-east-1"
}

# create lists implicitly using brackets [...]
variable "cidrs1" { default = [] }

# create lists explicitly
variable "cidrs" { type = "list" }

variable "amis" {
  type = "map"
  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
  }
}

variable "amis2" {
  type = "map"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "example" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
}

resource "aws_instance" "example2" {
  ami = "${var.amis["us-east-1"]}"
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.example.id}"
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}
