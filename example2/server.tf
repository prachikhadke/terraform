provider "aws" {
  region     = "us-east-1"
}

resource "aws_key_pair" "chef_server" {
  key_name = "chef_server"
  public_key = "${var.chef_server_ssh_public_key}"
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "chef-aws-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

/*
   NAT Instance
 */
resource "aws_security_group" "chef_server" {
  name = "chef_server"
  description = "Allow public inbound icmp echo request, ssh; allow all outbound"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.private_subnet_cidr}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = -1
      to_port = -1
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
      from_port = -1
      to_port = -1
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "chef_server"
  }
}

resource "aws_instance" "chef_server" {
  ami           = "${lookup(var.amis, var.aws_region)}"
  availability_zone = "${var.aws_availability_zone}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.chef_server.id}"]
  key_name = "${aws_key_pair.chef_server.key_name}"
  vpc_security_group_ids = ["${aws_security_group.chef_server.id}"]
  subnet_id = "${aws_subnet.aws_region_public.id}"
  associate_public_ip_address = true
  source_dest_check = false
}

resource "aws_eip" "chef_server" {
  instance = "${aws_instance.chef_server.id}"
  vpc      = true
}

output "chef_server_elastic_ip" {
    value = "${aws_eip.chef_server.public_ip}"
}

output "chef_server_ssh_public_key" {
  value = "${chef_server_ssh_public_key}"
}

/*
  Public subnet
 */
resource "aws_subnet" "aws_region_public" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "${var.aws_availability_zone}"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "aws_region_public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "aws_region_public" {
    subnet_id = "${aws_subnet.aws_region_public.id}"
    route_table_id = "${aws_route_table.aws_region_public.id}"
}

/*
  Private Subnet
*/
resource "aws_subnet" "aws_region_private" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "${var.aws_availability_zone}"

    tags {
        Name = "Private Subnet"
    }
}

resource "aws_route_table" "aws_region_private" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.chef_server.id}"
    }

    tags {
        Name = "Private Subnet"
    }
}

resource "aws_route_table_association" "aws_region_private" {
    subnet_id = "${aws_subnet.aws_region_private.id}"
    route_table_id = "${aws_route_table.aws_region_private.id}"
}
