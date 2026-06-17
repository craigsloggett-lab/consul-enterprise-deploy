# Consul Enterprise Deployment

An infrastructure as code repository used to deploy a Consul Enterprise cluster to AWS.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 5.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | ~> 5.9 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_consul"></a> [consul](#module\_consul) | git::https://github.com/craigsloggett/terraform-aws-consul-enterprise | c921de2d8d5fd782725b432ea15a8650cc4e58f5 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_consul_api_allowed_cidrs"></a> [consul\_api\_allowed\_cidrs](#input\_consul\_api\_allowed\_cidrs) | CIDR blocks allowed to reach the Consul API (port 8501) from outside the VPC. Only effective when nlb\_internal is false. | `list(string)` | `[]` | no |
| <a name="input_consul_enterprise_license"></a> [consul\_enterprise\_license](#input\_consul\_enterprise\_license) | Consul Enterprise license string. | `string` | n/a | yes |
| <a name="input_consul_server_instance_type"></a> [consul\_server\_instance\_type](#input\_consul\_server\_instance\_type) | EC2 instance type for Consul server nodes. | `string` | `"m5.large"` | no |
| <a name="input_ec2_ami_name"></a> [ec2\_ami\_name](#input\_ec2\_ami\_name) | Name filter for the AMI (supports wildcards). | `string` | n/a | yes |
| <a name="input_ec2_ami_owner"></a> [ec2\_ami\_owner](#input\_ec2\_ami\_owner) | AWS account ID of the AMI owner. | `string` | n/a | yes |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | Name of an existing EC2 key pair for SSH access. | `string` | n/a | yes |
| <a name="input_nlb_internal"></a> [nlb\_internal](#input\_nlb\_internal) | Whether the NLB is internal. | `bool` | `true` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name prefix for all resources. | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | Name of the existing Route 53 hosted zone. | `string` | n/a | yes |
| <a name="input_vault_pki_ca_chain_ssm_parameter_name"></a> [vault\_pki\_ca\_chain\_ssm\_parameter\_name](#input\_vault\_pki\_ca\_chain\_ssm\_parameter\_name) | SSM parameter name holding the external Vault PKI CA chain PEM, used by the Consul nodes' Vault Agents to trust the Vault server. Sourced from the vault-enterprise-deploy workspace's `vault_pki_ca_chain_ssm_parameter_name` output. | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name tag of the existing VPC. | `string` | n/a | yes |

## Resources

| Name | Type |
| ---- | ---- |
| [random_id.gossip_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [tls_locally_signed_cert.consul_int](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.consul_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.consul_ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [vault_aws_auth_backend_role.consul_server](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/aws_auth_backend_role) | resource |
| [vault_kv_secret_v2.consul_gossip](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) | resource |
| [vault_mount.consul_int](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_mount.kv](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_pki_secret_backend_config_urls.consul_int](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_config_urls) | resource |
| [vault_pki_secret_backend_intermediate_cert_request.consul_int](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_cert_request) | resource |
| [vault_pki_secret_backend_intermediate_set_signed.consul_int](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_intermediate_set_signed) | resource |
| [vault_pki_secret_backend_role.consul_server](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/pki_secret_backend_role) | resource |
| [vault_policy.consul_server_base](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_ssm_parameter.vault_ca_chain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_acl_management_token_secret_arn"></a> [acl\_management\_token\_secret\_arn](#output\_acl\_management\_token\_secret\_arn) | Secrets Manager ARN holding the Consul ACL management token. |
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | Public IP of the bastion host. |
| <a name="output_bootstrap_consul_cluster_state_ssm_parameter_name"></a> [bootstrap\_consul\_cluster\_state\_ssm\_parameter\_name](#output\_bootstrap\_consul\_cluster\_state\_ssm\_parameter\_name) | SSM parameter for the bootstrap initialization state flag. |
| <a name="output_bootstrap_consul_pki_ca_chain_ssm_parameter_name"></a> [bootstrap\_consul\_pki\_ca\_chain\_ssm\_parameter\_name](#output\_bootstrap\_consul\_pki\_ca\_chain\_ssm\_parameter\_name) | SSM parameter holding the PEM CA chain that signs the Consul server certificates. |
| <a name="output_bootstrap_instance_id_ssm_parameter_name"></a> [bootstrap\_instance\_id\_ssm\_parameter\_name](#output\_bootstrap\_instance\_id\_ssm\_parameter\_name) | SSM parameter for the elected bootstrap node EC2 instance ID. |
| <a name="output_consul_asg_name"></a> [consul\_asg\_name](#output\_consul\_asg\_name) | Name of the Consul Auto Scaling Group. |
| <a name="output_consul_datacenter"></a> [consul\_datacenter](#output\_consul\_datacenter) | Consul datacenter name. |
| <a name="output_consul_snapshots_bucket"></a> [consul\_snapshots\_bucket](#output\_consul\_snapshots\_bucket) | S3 bucket for Consul snapshots. |
| <a name="output_consul_url"></a> [consul\_url](#output\_consul\_url) | URL of the Consul Enterprise cluster. |
| <a name="output_consul_version"></a> [consul\_version](#output\_consul\_version) | Consul Enterprise version deployed. |
| <a name="output_ec2_ami_name"></a> [ec2\_ami\_name](#output\_ec2\_ami\_name) | Name of the AMI used for EC2 instances. |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the Consul server IAM role bound to the external Vault AWS auth role. |
| <a name="output_nlb_dns_name"></a> [nlb\_dns\_name](#output\_nlb\_dns\_name) | AWS-assigned DNS name of the Consul NLB. |
<!-- END_TF_DOCS -->
