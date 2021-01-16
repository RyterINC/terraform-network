terraform {
  backend "s3" {
    bucket = "network-base-earth"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}
