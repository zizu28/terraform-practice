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

variable "backup_retention_period" {
  description = "Days to retain backup. Must be > 0 to enable replication"
  type = number
  default = null
}

variable "replicate_source_db" {
  description = "If specified, replicate the RDS at the given ARN."
  type = string
  default = null
}
