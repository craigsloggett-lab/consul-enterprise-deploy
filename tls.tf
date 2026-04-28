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

# Server Certificate

resource "tls_private_key" "consul_server" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "consul_server" {
  private_key_pem = tls_private_key.consul_server.private_key_pem

  subject {
    common_name = "consul.${var.route53_zone_name}"
  }

  dns_names = [
    "server.${data.aws_region.current.region}.consul",
    "*.${var.route53_zone_name}",
    "consul.${var.route53_zone_name}",
    "localhost",
  ]

  ip_addresses = ["127.0.0.1"]
}

resource "tls_locally_signed_cert" "consul_server" {
  cert_request_pem   = tls_cert_request.consul_server.cert_request_pem
  ca_private_key_pem = tls_private_key.consul_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# Gossip Encryption Key

resource "random_id" "gossip_key" {
  byte_length = 32
}
