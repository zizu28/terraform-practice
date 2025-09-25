terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "zizu-terraform-up-and-running"
    key = "live/stage/webserver-cluster/terraform.tfstate"
    use_lockfile = true
    encrypt = true
  }
}


provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}


module "webserver_cluster" {
  source = "../../../modules/services/web-server"
  
  ami = "ami-0360c520857e3138f"
  cluster_name = "webserver-stage"
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  db_remote_state_bucket = "zizu-terraform-up-and-running"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
  enable_autoscaling = false
  server_text = "New server text"
  server_port = 8081
}
