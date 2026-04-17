variable "project_name" {
  type        = string
  description = "Name prefix for all resources."
}

variable "vpc_name" {
  type        = string
  description = "Name tag of the existing VPC."
}

variable "route53_zone_name" {
  type        = string
  description = "Name of the existing Route 53 hosted zone."
}

variable "consul_license" {
  type        = string
  description = "Consul Enterprise license string."
  sensitive   = true
}

variable "ec2_key_pair_name" {
  type        = string
  description = "Name of an existing EC2 key pair for SSH access."
}

variable "ec2_ami_owner" {
  type        = string
  description = "AWS account ID of the AMI owner."
}

variable "ec2_ami_name" {
  type        = string
  description = "Name filter for the AMI (supports wildcards)."
}

variable "nlb_internal" {
  type        = bool
  description = "Whether the NLB is internal."
  default     = true
}

variable "consul_api_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the Consul API (port 8501) from outside the VPC. Only effective when nlb_internal is false."
  default     = []
}

variable "consul_server_instance_type" {
  type        = string
  description = "EC2 instance type for Consul server nodes."
  default     = "m5.large"
}

variable "vault_tls_ca_bundle_ssm_parameter_name" {
  type        = string
  description = "SSM parameter name to fetch the Vault CA PEM."
  default     = "/lab/vault/tls/ca-bundle"
}

variable "vault_iam_role_name" {
  type        = string
  description = "Name of the Vault server IAM role (e.g., lab-vault-xxxxxxxx). Used to grant Vault's AWS auth method permission to resolve the Consul server IAM role during login."
}
