provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}

resource "aws_security_group" "simple_instance_sg"{
  name = "simple-instance-security-group"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "simple_instance" {
  ami = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.simple_instance_sg.id]
  user_data = <<-EOF
              #!/bin/bash
	      echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  tags = {
    Name = "Terraform-provisioned-instance"
  }
}

resource "aws_launch_configuration" "asg_launch_config" {
  image_id = "ami-0360c520857e3138f"
  instance_type = "t2.micro"
  security_groups = [aws_instance.simple_instance_sg.id]
  user_data = <<-EOF
  	      #!/bin/bash
	      echo "Hello, World" > index.html
	      nohup busybox httpd -f -p ${var.server_port} &
	      EOF
  lifecycle {
    create_before-destroy = true
  }
}

resource "aws_autoscaling_group" "webserver_asg" {
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  vpc_zone_identifiers = data.aws_subnets.default_vpc_subnets.ids
  target_group_arns = [aws_lb_target_group.asg_lb_target_group.arn]
  health_check_type = "ELB"

  min = 2
  max = 5
  tag {
    key = "Name"
    value = "Terraform-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "webserver_lb" {
  name = "Terraform-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default_vpc_sebnets.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "webserver_lb_listener" {
  load_balancer_arn = aws_lb.webserver_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "webserver_lb_listener_rule" {
  listener_arn = aws_lb_listener.webserver_lb_listener.arn
  priority = 100

  condition {
    path_pattern {
      values = [*]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg_lb_target_group.arn
  }
}

resource "aws_security_group" "alb_sg" {
  name = "Terraform-webserver-alb-sg"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg_lb_target_group" {
  name = "Terraform-webserver-asg-lb-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name = "vpc_id"
    values = [data.aws_vpc.default_vpc.id]  
  }
}
