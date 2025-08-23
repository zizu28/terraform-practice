output "instance_public_ip" {
  description = "The EC2 instance public IP"
  value = aws_instance.simple_instance.public_ip
}
