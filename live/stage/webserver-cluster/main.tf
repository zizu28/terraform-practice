module "webserver_cluster" {
  source = "../../../modules/services/web-server"
  cluster_name = "webservers-prod"
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  db_remote_state_bucket = "zizu-terraform-up-and-running"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
}
