output "consul_url" {
  description = "URL of the Consul cluster."
  value       = module.consul.consul_url
}

output "consul_version" {
  description = "Consul Enterprise version deployed."
  value       = module.consul.consul_version
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host."
  value       = module.consul.bastion_public_ip
}

output "consul_asg_name" {
  description = "Name of the Consul Auto Scaling Group."
  value       = module.consul.consul_asg_name
}

output "consul_snapshots_bucket" {
  description = "S3 bucket for Consul snapshots."
  value       = module.consul.consul_snapshots_bucket
}

output "consul_target_group_arn" {
  description = "ARN of the Consul NLB target group."
  value       = module.consul.consul_target_group_arn
}

output "ec2_ami_name" {
  description = "Name of the AMI used for EC2 instances."
  value       = module.consul.ec2_ami_name
}

#output "consul_tls_ca_bundle_ssm_parameter_name" {
#  description = "SSM parameter name for the Consul PKI TLS CA bundle."
#  value       = module.consul.consul_tls_ca_bundle_ssm_parameter_name
#}
#
#output "consul_pki_intermediate_ca_csr_ssm_parameter_name" {
#  description = "SSM parameter name where the Consul intermediate CA CSR is published."
#  value       = module.consul.consul_pki_intermediate_ca_csr_ssm_parameter_name
#}
#
#output "consul_pki_intermediate_ca_signed_csr_secret_arn" {
#  description = "Secrets Manager ARN for the signed Consul intermediate CA certificate."
#  value       = module.consul.consul_pki_intermediate_ca_signed_csr_secret_arn
#}

output "consul_gossip_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Consul gossip encryption key."
  value       = module.consul.gossip_key_secret.arn
}

output "consul_bootstrap_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Consul ACL bootstrap token."
  value       = module.consul.bootstrap_token_secret.arn
}

#output "consul_agent_token_secret_arn" {
#  description = "ARN of the Secrets Manager secret containing the Consul server agent ACL token."
#  value       = module.consul.consul_agent_token_secret_arn
#}

output "consul_security_group_id" {
  description = "ID of the Consul cluster security group."
  value       = module.consul.security_group.id
}

output "consul_auto_join_ec2_tag" {
  description = "EC2 tag key and value used for Consul auto-join."
  value       = module.consul.consul_auto_join_ec2_tag
}

output "consul_datacenter" {
  description = "Consul datacenter name."
  value       = module.consul.datacenter
}
