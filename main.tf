data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-private-*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-public-*"]
  }
}

data "aws_route53_zone" "consul" {
  name = var.route53_zone_name
}

data "aws_ami" "selected" {
  most_recent = true
  owners      = [var.ec2_ami_owner]

  filter {
    name   = "name"
    values = [var.ec2_ami_name]
  }
}

module "consul" {
  source = "../../craigsloggett/terraform-aws-consul-enterprise"

  project_name              = var.project_name
  route53_zone              = data.aws_route53_zone.consul
  consul_enterprise_license = var.consul_enterprise_license
  ec2_key_pair_name         = var.ec2_key_pair_name
  ec2_ami                   = data.aws_ami.selected

  consul_gossip_key = random_id.gossip_key.b64_std

  vault_address        = var.vault_address
  vault_ca_cert_pem    = var.vault_ca_cert_pem
  vault_aws_auth_role  = vault_aws_auth_backend_role.consul_server.role
  vault_pki_mount_path = vault_mount.consul_int.path
  vault_pki_role_name  = vault_pki_secret_backend_role.consul_server.name
  vault_agent_version  = var.vault_agent_version

  iam_role_name = local.consul_iam_role_name

  existing_vpc = {
    vpc_id             = data.aws_vpc.selected.id
    private_subnet_ids = data.aws_subnets.private.ids
    public_subnet_ids  = data.aws_subnets.public.ids
  }

  nlb_internal                = var.nlb_internal
  consul_api_allowed_cidrs    = var.consul_api_allowed_cidrs
  consul_server_instance_type = var.consul_server_instance_type
  consul_datacenter           = data.aws_region.current.region
}
