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

# The external Vault cluster signs its own server certificate from its PKI; the
# Vault Agents on the Consul nodes need that CA chain to trust it. It is published
# to SSM by the vault-enterprise-deploy workspace.
data "aws_ssm_parameter" "vault_ca_chain" {
  name = var.vault_pki_ca_chain_ssm_parameter_name
}

module "consul" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/craigsloggett/terraform-aws-consul-enterprise?ref=145a7b63d98cd6c177a54de80237234d1408ba6c"

  consul_enterprise_license = var.consul_enterprise_license
  consul_fqdn               = "consul.${var.route53_zone_name}"

  external_vault = {
    address      = local.vault_address
    port         = 443
    ca_chain_pem = data.aws_ssm_parameter.vault_ca_chain.value

    # The auth role is configured in vault_phase1.tf. It is referenced by name
    # rather than resource attribute to avoid a dependency cycle (that role binds
    # to this module's IAM role); the Vault Agents authenticate against it at
    # runtime once the apply has created it.
    auth_aws = {
      mount_path = "aws"
      role_name  = "consul-server"
    }

    pki = {
      mount_path = vault_mount.consul_int.path
      role_name  = vault_pki_secret_backend_role.consul_server.name
    }

    kv = {
      mount_path         = vault_mount.kv.path
      gossip_secret_path = vault_kv_secret_v2.consul_gossip.name
      gossip_key_field   = "key"
    }
  }

  route53_zone = data.aws_route53_zone.consul

  # The PKI role only permits server.<datacenter>.consul when the datacenter is
  # the region, so keep them aligned.
  consul = {
    datacenter = data.aws_region.current.region
  }

  # m5.large cannot sustain the module's default provisioned IOPS/throughput, so
  # hold the data and audit volumes at the gp3 floor.
  compute = {
    instance_type = var.consul_server_instance_type
    node_count    = 3

    raft_data_disk = {
      iops       = 3000
      throughput = 125
    }

    audit_disk = {
      iops       = 3000
      throughput = 125
    }
  }

  # Match the IAM role name the AWS auth role in vault_phase1.tf is bound to.
  iam_role = {
    name = local.consul_iam_role_name
  }

  key_pair = {
    key_name = var.ec2_key_pair_name
  }

  ami = {
    owners = [var.ec2_ami_owner]
    name   = var.ec2_ami_name
  }

  vpc = {
    existing = {
      vpc_id             = data.aws_vpc.selected.id
      private_subnet_ids = data.aws_subnets.private.ids
      public_subnet_ids  = data.aws_subnets.public.ids
    }
  }

  nlb = {
    internal            = var.nlb_internal
    api_allowed_cidrs   = var.consul_api_allowed_cidrs
    deletion_protection = false
  }

  consul_snapshot = {
    aws_s3_bucket = {
      force_destroy = true
    }
  }
}
