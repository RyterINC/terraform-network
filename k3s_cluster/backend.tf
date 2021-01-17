terraform {
  backend "s3" {
    bucket = "network-base-earth"
    key    = "k3s_cluster/terraform.tfstate"
    region = "us-east-1"
  }
}
