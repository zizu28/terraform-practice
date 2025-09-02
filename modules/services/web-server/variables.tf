variable "server_port" {
  description = "The port the server will use for HTTP requests."
  type = number
}

variable "ami" {
  description = "The EC2 AMI to provision"
  type = string
}

variable "cluster_name" {
  description = "The name to use for all clusters"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The s3 bucket name for terraform_remote_state configuration"
  type = string
}

variable "db_remote_state_key" {
  description = "The s3 key for terraform_remote_state configuration"
  type = string
}

variable "instance_type" {
  description = "The type of EC2 instance to run (e.g. t2.micro)"
  type = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances to run in the ASG"
  type = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances to run in the ASG"
  type = number
}
