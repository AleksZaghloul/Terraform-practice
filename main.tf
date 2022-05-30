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

resource "aws_s3_bucket_acl" "terraform_course" {
  bucket = aws_s3_bucket.terraform_course.id
  acl    = "private"
}

resource "aws_s3_bucket" "terraform_course"{
  bucket            = "tf-course-20220530"
  tags = {
    "Terraform" = "True"
  }
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-west-2a"
  tags = {
    "Terraform" = "True"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-west-2b"
  tags = {
    "Terraform" = "True"
  }
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

resource "aws_elb" "webserver"{
  name      = "terraform-elb"
  instances = aws_instance.webserver.*.id
  subnets   = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.webserver.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

}