terraform {
  backend "s3" {
    bucket = "zizu-terraform-up-and-running"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
    use_lockfile = true
    encrypt = true
  }
}


provider "aws" {
  region = "us-east-1"
  profile = "terraform"
}


resource "aws_s3_bucket" "terraform_backend" {
  bucket = "zizu-terraform-up-and-running"

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.terraform_backend.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "s3_sse_config" {
  bucket = aws_s3_bucket.terraform_backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_backend.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


resource "aws_dynamodb_table" "terraform_locks" {
  name = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
