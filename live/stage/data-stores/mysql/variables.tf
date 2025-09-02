variable "db_username" {
  description = "The RDS username"
  type = string
  sensitive = true
}


variable "db_password" {
  description = "The RDS password"
  type = string
  sensitive = true
}
