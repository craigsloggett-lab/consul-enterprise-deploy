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
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/craigsloggett/terraform-aws-consul-enterprise?ref=dfcbf8c17acc3f9cbfeb3a073d5111e7a4c51bf9"

  project_name              = var.project_name
  route53_zone              = data.aws_route53_zone.consul
  consul_enterprise_license = var.consul_enterprise_license
  ec2_key_pair_name         = var.ec2_key_pair_name
  ec2_ami                   = data.aws_ami.selected

  consul_ca_cert_pem     = tls_self_signed_cert.consul_ca.cert_pem
  consul_server_cert_pem = "${vault_pki_secret_backend_cert.consul_server.certificate}\n${vault_pki_secret_backend_cert.consul_server.issuing_ca}"
  consul_server_key_pem  = vault_pki_secret_backend_cert.consul_server.private_key
  consul_gossip_key      = random_id.gossip_key.b64_std

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
