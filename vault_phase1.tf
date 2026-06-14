resource "vault_pki_secret_backend_role" "consul_server" {
  backend = vault_mount.consul_int.path
  name    = "consul-server"

  allowed_domains = [
    "server.${data.aws_region.current.region}.consul",
    var.route53_zone_name,
    "localhost",
  ]
  allow_subdomains   = true
  allow_localhost    = true
  allow_bare_domains = true
  allow_ip_sans      = true
  server_flag        = true
  client_flag        = true
  key_type           = "ec"
  key_bits           = 384
  max_ttl            = "720h" # 30 days
  ttl                = "168h" # 7 days
  no_store           = true

  depends_on = [vault_pki_secret_backend_intermediate_set_signed.consul_int]
}

# Bind this deployment's Consul server IAM role to a Vault AWS IAM auth role,
# mirroring the vault-enterprise module's own auth role (auth_type iam, bound by
# principal ARN). resolve_aws_unique_ids is false so Vault matches the role ARN
# directly and never calls iam:GetRole on it; doing so would require granting the
# external Vault cluster's own server role permission over this deployment's
# role, coupling the two deployments.
resource "vault_aws_auth_backend_role" "consul_server" {
  backend                  = "aws"
  role                     = "consul-server"
  auth_type                = "iam"
  bound_iam_principal_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.consul_iam_role_name}"]
  resolve_aws_unique_ids   = false
  token_policies           = [vault_policy.consul_server_base.name]
  token_ttl                = 3600
  token_max_ttl            = 14400
}

resource "vault_policy" "consul_server_base" {
  name = "consul-server-base"

  policy = <<-EOT
    path "${vault_mount.consul_int.path}/issue/${vault_pki_secret_backend_role.consul_server.name}" {
      capabilities = ["update"]
    }

    path "${vault_mount.kv.path}/data/${vault_kv_secret_v2.consul_gossip.name}" {
      capabilities = ["read"]
    }
  EOT
}
