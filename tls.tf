# Self-Signed CA

resource "tls_private_key" "consul_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "consul_ca" {
  private_key_pem = tls_private_key.consul_ca.private_key_pem

  subject {
    common_name = "${title(var.project_name)} Consul CA"
  }

  validity_period_hours = 87600
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# Gossip Encryption Key

resource "random_id" "gossip_key" {
  byte_length = 32
}

# Consul Server Certificate (issued by Vault PKI intermediate)

resource "vault_pki_secret_backend_cert" "consul_server" {
  backend     = vault_mount.consul_int.path
  name        = vault_pki_secret_backend_role.consul_server.name
  common_name = "consul.${var.route53_zone_name}"

  alt_names = [
    "server.${data.aws_region.current.region}.consul",
    "consul.${var.route53_zone_name}",
    "localhost",
  ]

  ip_sans = ["127.0.0.1"]
}
