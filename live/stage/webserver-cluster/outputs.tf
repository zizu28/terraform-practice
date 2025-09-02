output "instance_public_ip" {
  description = "The EC2 instance public IP"
  value = aws_instance.simple_instance.public_ip
}

output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer"
}
