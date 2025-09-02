resource "aws_security_group" "simple_instance_sg"{
  name = "${var.cluster_name}-instance"
}

resource "aws_security_group_rule" "all_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.simple_instance_sg.id
  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_instance" "simple_instance" {
  ami = var.ami
  instance_type = var.instance_type
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
  image_id = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.simple_instance_sg.id]
  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  })
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webserver_asg" {
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  vpc_zone_identifier = data.aws_subnets.default_vpc_subnets.ids
  target_group_arns = [aws_lb_target_group.asg_lb_target_group.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size
  tag {
    key = "Name"
    value = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_lb" "webserver_lb" {
  name = "Terraform-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default_vpc_subnets.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "webserver_lb_listener" {
  load_balancer_arn = aws_lb.webserver_lb.arn
  port = local.http_port
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
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg_lb_target_group.arn
  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb_target_group" "asg_lb_target_group" {
  name = "webserver-asg-lb-target-group"
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
    name = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]  
  }
}


data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket 
    key = var.db_remote_state_key
    region = "us-east-1"
  }
}

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}
