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

#resource "aws_launch_configuration" "asg_launch_config" {
resource "aws_launch_template" "asg_launch_config" {
  image_id = var.ami
  instance_type = var.instance_type
#  security_groups = [aws_security_group.simple_instance_sg.id]
  vpc_security_group_ids = [aws_security_group.simple_instance_sg.id]
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    server_text = var.server_text
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }))
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webserver_asg" {
#  launch_configuration = aws_launch_configuration.asg_launch_config.name
  name = var.cluster_name
  launch_template {
    id = aws_launch_template.asg_launch_config.id
    version = "$Latest"
  }

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

  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags:
      key => upper(value)
      if key != "Name"
    }
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "${var.cluster_name}-scale_out_during_business_hours"
  min_size = 2
  max_size = 10
  desired_capacity = 5
  recurrence = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name = "${var.cluster_name}-scale_in_at_night"
  min_size = 2
  max_size = 5
  desired_capacity = 3
  recurrence = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
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

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name = "${var.cluster_name}-high-cpu-utilization"
  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webserver_asg.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  period = 300
  statistic = "Average"
  threshold = 90
  unit = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count = format("%.1s", var.instance_type) == "t" ? 1 : 0
  alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
  namespace = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webserver_asg.name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods = 1
  period = 300
  statistic = "Minimum"
  threshold = 10
  unit = "Count"
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
