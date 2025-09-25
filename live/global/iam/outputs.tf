output "all_arns" {
  description = "All IAM users"
  value = values(aws_iam_user.iam)[*].arn
}

output "carlos_cloudwatch_policy_arn" {
  value = one(concat(
    aws_iam_user_policy_attachment.carlos_cloudwatch_full_access[*].policy_arn,
    aws_iam_user_policy_attachment.carlos_cloudwatch_readonly_access[*].policy_arn))
}
