resource "aws_iam_access_key" "remote_write" {
  user = aws_iam_user.remote_write.name
}

resource "aws_iam_user" "remote_write" {
  name = "prom-remote_write"
  path = "/system/"
}

data "aws_iam_policy_document" "remote_write" {
  statement {
    effect    = "Allow"
    actions   = ["aps:RemoteWrite"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "remote_write" {
  name   = "prom-remote_write"
  user   = aws_iam_user.remote_write.name
  policy = data.aws_iam_policy_document.remote_write.json
}
