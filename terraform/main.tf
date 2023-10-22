provider "aws" {}

data "aws_region" "self" {}

locals {
  xray_server = {
    name     = "xray-server"
    ami      = "ami-0aaa5410833273cfe"
    ssh_user = "ubuntu"
    type     = "t3.nano"
  }
}

variable "private_key_file" {
  type        = string
  description = "Private key to use to ssh into xray_server"
  default     = "~/.ssh/id_ed25519"
}

data "tls_public_key" "self" {
  private_key_openssh = file(var.private_key_file)
}

resource "aws_key_pair" "self" {
  key_name   = "${local.xray_server.name}-${terraform.workspace}"
  public_key = data.tls_public_key.self.public_key_openssh
}

resource "aws_instance" "self" {
  # https://eu-west-2.console.aws.amazon.com/ec2/home?region=eu-west-2#ImageDetails:imageId=ami-0aaa5410833273cfe
  # ubuntu 22.04
  ami           = local.xray_server.ami
  subnet_id     = aws_subnet.self.id
  instance_type = local.xray_server.type

  # Note that ipv4 would become non-free starting from 1 Feb 2024
  # but without this access to internet from ec2 via ipv4 is not allowed and xray cannot work with ipv6 outbound..
  associate_public_ip_address = true

  credit_specification {
    cpu_credits = "standard"
  }

  key_name = aws_key_pair.self.key_name

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
  }

  vpc_security_group_ids = [aws_security_group.self.id]

  tags = {
    Name = "${local.xray_server.name}-${terraform.workspace}"
  }
}

resource "aws_vpc" "self" {
  assign_generated_ipv6_cidr_block = "true"
  cidr_block                       = "172.32.0.0/16"
}

resource "aws_internet_gateway" "self" {
  vpc_id = aws_vpc.self.id
}

resource "aws_default_route_table" "self" {
  default_route_table_id = aws_vpc.self.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.self.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.self.id
  }
}

resource "aws_subnet" "self" {
  vpc_id                                         = aws_vpc.self.id
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.self.ipv6_cidr_block, 8, 20)
  cidr_block                                     = cidrsubnet(aws_vpc.self.cidr_block, 8, 0)
  enable_resource_name_dns_aaaa_record_on_launch = "true"
  assign_ipv6_address_on_creation                = "true"
}

resource "aws_security_group" "self" {
  vpc_id = aws_vpc.self.id

  egress {
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    protocol  = "-1"
    self      = "false"
    to_port   = 0
  }

  ingress {
    ipv6_cidr_blocks = ["::/0"]
    description      = "xray"
    from_port        = "443"
    protocol         = "tcp"
    self             = "false"
    to_port          = "443"
  }

  ingress {
    ipv6_cidr_blocks = ["::/0"]
    description      = "certbot"
    from_port        = "80"
    protocol         = "tcp"
    self             = "false"
    to_port          = "80"
  }

  ingress {
    ipv6_cidr_blocks = ["::/0"]
    description      = "ssh"
    from_port        = "22"
    protocol         = "tcp"
    self             = "false"
    to_port          = "22"
  }
}

output "xray_server_ipv6" {
  value       = aws_instance.self.ipv6_addresses[0]
  description = "IPv6 of the xray server"
}

output "xray_server_aws_region" {
  value       = data.aws_region.self.name
  description = "AWS region of the xray server"
}

output "xray_server_user" {
  value       = local.xray_server.ssh_user
  description = "SSH user to connect to the xray server"
}
