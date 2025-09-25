provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}


module "webserver_cluster" {
  source = "../../../../modules/services/web-server"
  cluster_name = "webservers-prod"
  instance_type = "t2.micro"
  server_port = 8081
  ami = "ami-0360c520857e3138f"
  min_size = 2
  max_size = 2
  db_remote_state_bucket = "zizu-terraform-up-and-running"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
  enable_autoscaling = true
  custom_tags = {
    Owner = "zizu"
    ManagedBy = "terraform"
  }
}
