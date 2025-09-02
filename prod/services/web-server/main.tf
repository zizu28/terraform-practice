provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}


module "webserver_cluster" {
  source = "../../../modules/services/web-server"
  cluster_name = "webservers-prod"
  instance_type = "t2.micro"
  server_port = 8081
  ami = "ami-0360c520857e3138f"
  min_size = 2
  max_size = 2
  db_remote_state_bucket = "zizu-terraform-up-and-running"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
}


resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 5
  recurrence = "0 9 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}


resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size = 2
  max_size = 5
  desired_capacity = 3
  recurrence = "0 17 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}
