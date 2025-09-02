output "instance_public_ip" {
  description = "The EC2 instance public IP"
  value = aws_instance.simple_instance.public_ip
}

output "alb_dns_name" {
  value = aws_lb.webserver_lb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value = aws_autoscaling_group.webserver_asg.name
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
  description = "The ID of the security group attached to the load balancer"
}
