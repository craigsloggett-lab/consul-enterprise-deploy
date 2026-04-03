output "consul_url" {
  description = "URL of the Consul cluster."
  value       = module.consul.consul_url
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host."
  value       = module.consul.bastion_public_ip
}

output "consul_private_ips" {
  description = "Private IPs of the Consul nodes."
  value       = module.consul.consul_private_ips
}

output "consul_target_group_arn" {
  description = "ARN of the Consul NLB target group."
  value       = module.consul.consul_target_group_arn
}

output "ec2_ami_name" {
  description = "Name of the AMI used for EC2 instances."
  value       = module.consul.ec2_ami_name
}

output "consul_ca_cert" {
  description = "CA certificate for trusting the Consul TLS chain."
  value       = module.consul.consul_ca_cert
  sensitive   = true
}

output "consul_ca_cert_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Consul CA certificate."
  value       = module.consul.ca_cert_secret.arn
}

output "consul_gossip_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Consul gossip encryption key."
  value       = module.consul.gossip_key_secret.arn
}

output "consul_token_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Consul ACL token for Nomad."
  value       = module.consul.nomad_token_secret.arn
}

output "consul_security_group_id" {
  description = "ID of the Consul cluster security group."
  value       = module.consul.security_group.id
}

output "consul_cluster_tag" {
  description = "EC2 tag key and value used for Consul auto-join."
  value       = module.consul.cluster_tag
}

output "consul_datacenter" {
  description = "Consul datacenter name."
  value       = module.consul.datacenter
}

output "nomad_server_service_name" {
  description = "Consul service name Nomad servers will register as."
  value       = module.consul.nomad_server_service_name
}

output "nomad_client_service_name" {
  description = "Consul service name Nomad clients will register as."
  value       = module.consul.nomad_client_service_name
}

output "nomad_snapshot_service_name" {
  description = "Consul service name the Nomad snapshot agent will register as."
  value       = module.consul.nomad_snapshot_service_name
}
