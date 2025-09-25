provider "aws" {
  region = "us-east-1"
  profile = "Zizu"
}


resource "aws_iam_user" "iam" {
#  count = 3
#  name = var.usernames[count.index]
  for_each = toset(var.usernames)
  name = each.value
}


resource "aws_iam_policy" "cloudwatch_readonly_policy" {
  name = "cloudwatch-readonly-policy"
  policy = data.aws_iam_policy_document.cloudwatch_readonly_policy.json
}

resource "aws_iam_policy" "cloudwatch_full_access_policy" {
  name = "cloudwatch-readonly-policy"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

resource "aws_iam_user_policy_attachment" "carlos_cloudwatch_full_access" {
  count = var.give_carlos_cloudwatch_access ? 1 : 0
  user = values(aws_iam_user.iam)[0].name
  policy_arn = aws_iam_policy.cloudwatch_full_access_policy.arn
}

resource "aws_iam_user_policy_attachment" "carlos_cloudwatch_readonly_access" {
  count = var.give_carlos_cloudwatch_access ? 0 : 1
  user = values(aws_iam_user.iam)[0].name
  policy_arn = aws_iam_policy.cloudwatch_readonly_policy.arn
}


data "aws_iam_policy_document" "cloudwatch_readonly_policy" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect = "Allow"
    actions = ["cloudwatch:*"]
    resources = ["*"]
  }
}

