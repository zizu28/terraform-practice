variable "server_port" {
  description = "The port the server will use for HTTP requests."
  type = number
}

variable "ami" {
  description = "The EC2 AMI to provision"
  type = string
}
