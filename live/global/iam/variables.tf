variable "usernames" {
  description = "IAM user names"
  type = list(string)
  default = ["carlos", "onyewu", "borger"]
}

variable "give_carlos_cloudwatch_access" {
  description = "If true, Carlos gets full access to cloudwatch resource"
  type = bool
}
