# Gossip Encryption Key
#
# The module's Vault Agents read this key from the external Vault KV store at
# runtime (the module no longer accepts it as an input), so it is written to a
# KV v2 mount the agents can reach. The external Vault's HCP Terraform run policy
# (admin.hcl) only permits KV data operations under `secret/`, so the gossip key
# lives in the `secret/` KV v2 mount rather than a dedicated one.

resource "random_id" "gossip_key" {
  byte_length = 32
}

resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv-v2"
  description = "Consul gossip encryption key"
}

resource "vault_kv_secret_v2" "consul_gossip" {
  mount = vault_mount.kv.path
  name  = "consul/gossip"

  data_json = jsonencode({
    key = random_id.gossip_key.b64_std
  })
}
