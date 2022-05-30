terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_security_group" "webserver"{
  name = "terraform-webserver"
  description = "Allow http and https access"
  
  ingress{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" = "True"
  }

}

resource "aws_instance" "webserver" {
  count = 2

  ami           = "ami-00af37d1144686454"
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.webserver.id
    ]

  tags = {
    "Terraform" = "True"
  }
}
resource "aws_eip_association" "webserver" {
  instance_id   = aws_instance.webserver.0.id
  allocation_id = aws_eip.webserver.id
  
}

resource "aws_eip" "webserver"{
  tags = {
    "Terraform" = "True"
  }
}
