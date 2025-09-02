terraform {
  backend "s3" {
    bucket = "zizu-terraform-up-and-running"
    key = "workspaces/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
} 


provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}


resource "aws_instance" "workspace_example" {
  ami = "ami-0360c520857e3138f"
  instance_type = "t2.micro"

  tags = {
    Name = "Workspace-example"
  }
}
