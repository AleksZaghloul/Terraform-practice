variable "cidr" {
  type = list(string)
  description = "traffic permitted"
}
variable "web_image_id" {
  type = string
  description = "web AMI"
}
variable "web_ec2_type" {
  type = string
  description = "web instance type "
}
variable "web_desired_cap" {
  type = number
}
variable "web_min_cap" {
  type = number
}
variable "web_max_cap" {
  type = number
}
variable "myIP" {
  type = list(string)
}


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
    cidr_blocks = var.cidr
  }

  ingress{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr
  }

  ingress{
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr
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

resource "aws_elb" "webserver"{
  name      = "terraform-elb"
#  instances = aws_instance.webserver.*.id
  subnets   = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.webserver.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

}
resource "aws_launch_template" "challenge" {
  name_prefix   = "challenge"
  image_id      = var.web_image_id
  instance_type = var.web_ec2_type
  vpc_security_group_ids = [aws_security_group.webserver.id]
  user_data = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "challenge" {
  availability_zones = ["us-west-2a", "us-west-2b"]
  desired_capacity   = var.web_desired_cap
  max_size           = var.web_max_cap
  min_size           = var.web_min_cap

  launch_template {
    id      = aws_launch_template.challenge.id
    version = "$Latest"
  }
  tag {
    key                 = "Terraform"
    value               = "True"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "challenge" {
  autoscaling_group_name = aws_autoscaling_group.challenge.id
  elb                    = aws_elb.webserver.id
}
