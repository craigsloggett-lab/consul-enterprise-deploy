# Self-Signed CA
#
# Anchors the `pki_consul` intermediate the module's Vault Agents issue Consul
# server certificates from at runtime.

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
