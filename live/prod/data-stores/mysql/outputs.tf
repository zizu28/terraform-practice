output "address" {
  description = "Connect to the database at this endpoint"
  value = aws_db_instance.rds.address
}


output "port" {
  description = "The port the database is listening on"
  value = aws_db_instance.rds.port
}
