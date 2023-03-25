terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.59.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "1.36.1"
    }
  }
}
