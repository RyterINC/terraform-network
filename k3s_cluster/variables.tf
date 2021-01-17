variable "remote_network_bucket_name" {
  type = string
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "remote_key_path" {
  type = string
  default = "network/terraform.tfstate"
}

variable "profile" {
  type = string
  default = "default"
}
