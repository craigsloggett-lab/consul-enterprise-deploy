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
  source = "git::https://github.com/craigsloggett/terraform-aws-consul-enterprise?ref=9af2a69c923287b74e4b46a7f7dc08dcb95f1ba9"

  project_name      = var.project_name
  route53_zone      = data.aws_route53_zone.consul
  consul_license    = var.consul_license
  ec2_key_pair_name = var.ec2_key_pair_name
  ec2_ami           = data.aws_ami.selected

  existing_vpc = {
    vpc_id             = data.aws_vpc.selected.id
    private_subnet_ids = data.aws_subnets.private.ids
    public_subnet_ids  = data.aws_subnets.public.ids
  }

  nlb_internal                           = var.nlb_internal
  consul_api_allowed_cidrs               = var.consul_api_allowed_cidrs
  consul_server_instance_type            = var.consul_server_instance_type
  vault_tls_ca_bundle_ssm_parameter_name = var.vault_tls_ca_bundle_ssm_parameter_name
  vault_iam_role_name                    = var.vault_iam_role_name
  vault_url                              = var.vault_url
}
