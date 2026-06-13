output "consul_url" {
  description = "URL of the Consul Enterprise cluster."
  value       = module.consul.consul_url
}

output "consul_version" {
  description = "Consul Enterprise version deployed."
  value       = module.consul.consul_version
}

output "consul_datacenter" {
  description = "Consul datacenter name."
  value       = module.consul.consul_datacenter
}

output "iam_role_arn" {
  description = "ARN of the Consul server IAM role bound to the external Vault AWS auth role."
  value       = module.consul.iam_role_arn
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host."
  value       = module.consul.bastion_public_ip
}

output "nlb_dns_name" {
  description = "AWS-assigned DNS name of the Consul NLB."
  value       = module.consul.nlb_dns_name
}

output "consul_asg_name" {
  description = "Name of the Consul Auto Scaling Group."
  value       = module.consul.autoscaling_group_name
}

output "ec2_ami_name" {
  description = "Name of the AMI used for EC2 instances."
  value       = module.consul.ami_name
}

output "consul_snapshots_bucket" {
  description = "S3 bucket for Consul snapshots."
  value       = module.consul.consul_snapshot_aws_s3_bucket_name
}

output "acl_management_token_secret_arn" {
  description = "Secrets Manager ARN holding the Consul ACL management token."
  value       = module.consul.acl_management_token_secret_arn
}

output "bootstrap_consul_cluster_state_ssm_parameter_name" {
  description = "SSM parameter for the bootstrap initialization state flag."
  value       = module.consul.bootstrap_consul_cluster_state_ssm_parameter_name
}

output "bootstrap_instance_id_ssm_parameter_name" {
  description = "SSM parameter for the elected bootstrap node EC2 instance ID."
  value       = module.consul.bootstrap_instance_id_ssm_parameter_name
}

output "bootstrap_consul_pki_ca_chain_ssm_parameter_name" {
  description = "SSM parameter holding the PEM CA chain that signs the Consul server certificates."
  value       = module.consul.bootstrap_consul_pki_ca_chain_ssm_parameter_name
}
