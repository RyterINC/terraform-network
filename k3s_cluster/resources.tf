terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
      shared_credentials_file = "~/.aws/credentials"
      profile = var.profile
      region = var.region
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.remote_network_bucket_name
    key    = var.remote_key_path
    region = var.region
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "bastion" {
  name   = "bastion-earth"
  vpc_id = data.terraform_remote_state.network.id
}

resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id     = element(data.terraform_remote_state.network.public_subnet_id, 0)
  user_data     = templatefile("${path.module}/bastion.tmpl", { ssh_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7g311R1h5YjaJUPsjU0eAGtyvNVKmckC6GFn1NAe7zoNgJYJvTppLIz3Su46V3ZRNEYgJ9ENjBkHwpUquUn5kct4hmfwYWWCYuXzsGbhUxjWEL5oTe65BqPG4iG5kLWL0QSvQR4UPGENkjh3xwUgMkEnKLe0IH5/q+tU5WjEiF/agg4VjkXc90hNm8WGQwep/WB+LxMluPMnlIq8vbgMSJARK8ShvLlvmoybyzbBiJREo9NAH1TxPirKDf2uFJuI54mHC+3+mRiuoU7diqvS72N2pEeF3Dyx2p3gLxy5yC3+RL+pzh0rptNliuBUa5AXhPPyOsj2Rv1YF+3Wd4wuFbZdtRJX1UkrkTMZ9IPCqV5xAZ0qCs8oUmWdesW+Sb05XC5bZbtxfHeDfPEszz/TPNwcPLff3L4fGon5nUYGL3HqpfSR1LDjVV9rqDeQnHfJpBtMLoIGjl1vR5LOzNGS2QHE2TDd/SBcUg0QkFCD9UI4ayK+etCmgV1k7KlolnHE= jayson@RyterINC"] })

  vpc_security_group_ids = [aws_security_group.bastion.id, data.terraform_remote_state.network.default_security_group_id]

  tags = {
    Name = "bastion-earth"
  }
}

module "k3s_rancher" {
  source                       = "rancher/aws-cluster/k3s"
  vpc_id                       = data.terraform_remote_state.network.id
  aws_region                   = var.region
  aws_profile                  = var.profile
  rancher_password             = "u7qmyhm3wbgujjuijs3rqfpm2e"
  install_rancher              = true
  install_certmanager          = true
  install_nginx_ingress        = true
  k3s_deploy_traefik           = false
  private_subnets              = data.terraform_remote_state.network.private_subnet_id
  public_subnets               = data.terraform_remote_state.network.public_subnet_id
  ssh_keys                     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7g311R1h5YjaJUPsjU0eAGtyvNVKmckC6GFn1NAe7zoNgJYJvTppLIz3Su46V3ZRNEYgJ9ENjBkHwpUquUn5kct4hmfwYWWCYuXzsGbhUxjWEL5oTe65BqPG4iG5kLWL0QSvQR4UPGENkjh3xwUgMkEnKLe0IH5/q+tU5WjEiF/agg4VjkXc90hNm8WGQwep/WB+LxMluPMnlIq8vbgMSJARK8ShvLlvmoybyzbBiJREo9NAH1TxPirKDf2uFJuI54mHC+3+mRiuoU7diqvS72N2pEeF3Dyx2p3gLxy5yC3+RL+pzh0rptNliuBUa5AXhPPyOsj2Rv1YF+3Wd4wuFbZdtRJX1UkrkTMZ9IPCqV5xAZ0qCs8oUmWdesW+Sb05XC5bZbtxfHeDfPEszz/TPNwcPLff3L4fGon5nUYGL3HqpfSR1LDjVV9rqDeQnHfJpBtMLoIGjl1vR5LOzNGS2QHE2TDd/SBcUg0QkFCD9UI4ayK+etCmgV1k7KlolnHE= jayson@RyterINC"]
  name                         = "earth"
  # k3s_cluster_secret           = "secretvaluechangeme"
  domain                       = "rancher-earth.thedevopsreport.com"
  aws_azs                      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  k3s_storage_endpoint         = "postgres"
  db_user                      = "admin"
  db_pass                      = "50cbf5597fd320b6a732ce778082a0359"
  extra_server_security_groups = [data.terraform_remote_state.network.default_security_group_id]
  extra_agent_security_groups  = [data.terraform_remote_state.network.default_security_group_id]
  private_subnets_cidr_blocks  = data.terraform_remote_state.network.private_subnets_cidr_blocks
}
