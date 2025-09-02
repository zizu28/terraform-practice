terraform {
  backend "s3" {
    bucket = "zizu-terraform-up-and-running"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}


provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}


resource "aws_db_instance" "rds" {
  identifier_prefix = "my-terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t3.micro"
  skip_final_snapshot = true
  db_name = "rds_database"
  username = var.db_username
  password = var.db_password
}
