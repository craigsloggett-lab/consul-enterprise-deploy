provider "aws" {
  region = "us-east-1"
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_admin_token
}
