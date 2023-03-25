provider "aws" {
  region     = "eu-west-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "grafana" {
  url  = "https://${aws_grafana_workspace.main.endpoint}"
  auth = aws_grafana_workspace_api_key.admin.key
}
