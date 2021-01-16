terraform {
  backend "s3" {
    bucket = "network-base-earth"
    key    = "network/terraform.state"
    region = "us-east-1"
  }
}
