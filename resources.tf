terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
      shared_credentials_file = "~/.aws/credentials"
      profile = "default"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}


data "aws_availability_zones" "available" {}

# NETWORKING #
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>2.0"

  name = "network-earth"

  cidr            = var.cidr_block
  azs             = slice(data.aws_availability_zones.available.names, 0, var.subnet_count)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = false

  create_database_subnet_group = false


  tags = {
    Environment = "earth"
  }
}
