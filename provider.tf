terraform {
  required_version = "1.4.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.23.1"
    }
  }
}

variable "aws_region" {
  default = "ap-northeast-1"
}

provider "aws" {
  region = var.aws_region
}
