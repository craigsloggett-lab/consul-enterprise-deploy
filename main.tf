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
  # TODO: Pin to a Git ref once the module is released.
  # source = "git::https://github.com/craigsloggett/terraform-aws-consul-enterprise?ref=vX.Y.Z"
  source = "../terraform-aws-consul-enterprise"

  project_name      = var.project_name
  route53_zone      = data.aws_route53_zone.consul
  consul_license    = var.consul_license
  ec2_key_pair_name = var.ec2_key_pair_name
  ec2_ami           = data.aws_ami.selected

  nlb_internal             = var.nlb_internal
  consul_api_allowed_cidrs = var.consul_api_allowed_cidrs
}
