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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["148.252.128.192/32"]
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
  image_id      = "ami-00af37d1144686454"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id]
  user_data = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "challenge" {
  availability_zones = ["us-west-2a", "us-west-2b"]
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2

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
