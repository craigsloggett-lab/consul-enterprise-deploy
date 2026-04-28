resource "vault_mount" "consul_int" {
  path                      = "pki_consul_int"
  type                      = "pki"
  default_lease_ttl_seconds = 86400    # 1 day
  max_lease_ttl_seconds     = 31536000 # 1 year
  description               = "Consul cluster intermediate CA"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "consul_int" {
  backend     = vault_mount.consul_int.path
  type        = "internal"
  common_name = "${title(var.project_name)} Consul Intermediate CA"
  key_type    = "ec"
  key_bits    = 384
}

resource "tls_locally_signed_cert" "consul_int" {
  cert_request_pem      = vault_pki_secret_backend_intermediate_cert_request.consul_int.csr
  ca_private_key_pem    = tls_private_key.consul_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.consul_ca.cert_pem
  validity_period_hours = 8760

  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "vault_pki_secret_backend_intermediate_set_signed" "consul_int" {
  backend     = vault_mount.consul_int.path
  certificate = "${tls_locally_signed_cert.consul_int.cert_pem}\n${tls_self_signed_cert.consul_ca.cert_pem}"
}

resource "vault_pki_secret_backend_config_urls" "consul_int" {
  backend                 = vault_mount.consul_int.path
  issuing_certificates    = ["${var.vault_address}/v1/${vault_mount.consul_int.path}/ca"]
  crl_distribution_points = ["${var.vault_address}/v1/${vault_mount.consul_int.path}/crl"]
}
