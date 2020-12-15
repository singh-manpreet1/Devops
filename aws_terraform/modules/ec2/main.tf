provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/home/manpreetsingh/.aws/credentials"
  profile = "default"
}


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "aws_ami" "Red_Hat" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "main" {
  ami = data.aws_ami.Red_Hat.id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  tags = {
    Name = var.name
  }
}
