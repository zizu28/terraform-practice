output "instance_public_ip" {
  description = "The EC2 instance public IP"
  value = aws_instance.simple_instance.public_ip
}

output "alb_dns_name" {
  value = aws_lb.webserver_lb.dns_name
  description = "The domain name of the load balancer"
}
