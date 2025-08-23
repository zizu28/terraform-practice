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
