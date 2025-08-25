output "s3_bucket_arn" {
  description = "The ARN of the s3 bucket."
  value = aws_s3_bucket.terraform_backend.arn
}


output "dynamodb_table_name" {
 description = "The name of the AWS dynamodb table"
 value = aws_dynamodb_table.terraform_locks.name
}
