resource "aws_grafana_workspace" "main" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  data_sources             = ["PROMETHEUS"]
}

resource "aws_grafana_workspace_api_key" "admin" {
  key_name        = "terraform"
  key_role        = "ADMIN"
  seconds_to_live = 3600
  workspace_id    = aws_grafana_workspace.main.id
}

data "aws_ssoadmin_instances" "default" {
}

data "aws_identitystore_user" "me" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.default.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = "damoun"
    }
  }
}

resource "aws_grafana_role_association" "admin" {
  role         = "ADMIN"
  user_ids     = [data.aws_identitystore_user.me.user_id]
  workspace_id = aws_grafana_workspace.main.id
}

resource "aws_iam_role" "grafana" {
  name = "grafana-assume"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "grafana" {
  name = "grafana"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          Effect = "Allow",
          Action = [
            "aps:DescribeWorkspace",
            "aps:ListWorkspaces",
            "aps:GetLabels",
            "aps:GetSeries",
            "aps:GetMetricMetadata",
            "aps:DescribeAlertManagerDefinition",
            "aps:DescribeRuleGroupsNamespace",
            "aps:DeleteRuleGroupsNamespace",
            "aps:ListRuleGroupsNamespaces",
            "aps:QueryMetrics"
          ],
          Resource = "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "grafana" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana.arn
}

output "grafana_url" {
  value = aws_grafana_workspace.main.endpoint
}

resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "Prometheus"
  url        = aws_prometheus_workspace.main.prometheus_endpoint
  is_default = true

  json_data_encoded = jsonencode({
    sigV4Auth     = true
    sigV4AuthType = "workspace-iam-role"
    sigV4Region   = "eu-west-1"
    manageAlerts  = true
    httpMethod    = "GET"
  })
}