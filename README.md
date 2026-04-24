# Consul Enterprise Deployment

An infrastructure as code repository used to deploy a Consul Enterprise cluster to AWS.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) | 0.76.2 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.1.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | 0.76.2 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_consul"></a> [consul](#module\_consul) | git::https://github.com/craigsloggett/terraform-aws-consul-enterprise | b68a1bbc4afe148c6dd64e2c0a0f229abc2319b7 |
| <a name="module_consul"></a> [consul](#module\_consul) | git::https://github.com/craigsloggett/terraform-aws-consul-enterprise | 3b9491a5c45d31102b73d13299c1bfe0d568f8c8 |

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
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name tag of the existing VPC. | `string` | n/a | yes |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_secretsmanager_secret_version.consul_pki_intermediate_ca_signed_csr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [terraform_data.wait_for_csr](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [tls_locally_signed_cert.consul_pki_intermediate_ca_signed_csr](https://registry.terraform.io/providers/hashicorp/tls/4.1.0/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.root_ca](https://registry.terraform.io/providers/hashicorp/tls/4.1.0/docs/resources/private_key) | resource |
| [tls_self_signed_cert.root_ca](https://registry.terraform.io/providers/hashicorp/tls/4.1.0/docs/resources/self_signed_cert) | resource |
| [aws_ami.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_ssm_parameter.consul_pki_intermediate_ca_csr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [tfe_organization.this](https://registry.terraform.io/providers/hashicorp/tfe/0.76.2/docs/data-sources/organization) | data source |
| [tfe_outputs.vault_enterprise_deploy](https://registry.terraform.io/providers/hashicorp/tfe/0.76.2/docs/data-sources/outputs) | data source |
| [tfe_workspace.vault_enterprise_deploy](https://registry.terraform.io/providers/hashicorp/tfe/0.76.2/docs/data-sources/workspace) | data source |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | Public IP of the bastion host. |
| <a name="output_consul_agent_token_secret_arn"></a> [consul\_agent\_token\_secret\_arn](#output\_consul\_agent\_token\_secret\_arn) | ARN of the Secrets Manager secret containing the Consul server agent ACL token. |
| <a name="output_consul_asg_name"></a> [consul\_asg\_name](#output\_consul\_asg\_name) | Name of the Consul Auto Scaling Group. |
| <a name="output_consul_auto_join_ec2_tag"></a> [consul\_auto\_join\_ec2\_tag](#output\_consul\_auto\_join\_ec2\_tag) | EC2 tag key and value used for Consul auto-join. |
| <a name="output_consul_bootstrap_token_secret_arn"></a> [consul\_bootstrap\_token\_secret\_arn](#output\_consul\_bootstrap\_token\_secret\_arn) | ARN of the Secrets Manager secret containing the Consul ACL bootstrap token. |
| <a name="output_consul_ca_cert"></a> [consul\_ca\_cert](#output\_consul\_ca\_cert) | CA certificate for trusting the Consul TLS chain. |
| <a name="output_consul_datacenter"></a> [consul\_datacenter](#output\_consul\_datacenter) | Consul datacenter name. |
| <a name="output_consul_gossip_key_secret_arn"></a> [consul\_gossip\_key\_secret\_arn](#output\_consul\_gossip\_key\_secret\_arn) | ARN of the Secrets Manager secret containing the Consul gossip encryption key. |
| <a name="output_consul_pki_intermediate_ca_csr_ssm_parameter_name"></a> [consul\_pki\_intermediate\_ca\_csr\_ssm\_parameter\_name](#output\_consul\_pki\_intermediate\_ca\_csr\_ssm\_parameter\_name) | SSM parameter name where the Consul intermediate CA CSR is published. |
| <a name="output_consul_pki_intermediate_ca_signed_csr_secret_arn"></a> [consul\_pki\_intermediate\_ca\_signed\_csr\_secret\_arn](#output\_consul\_pki\_intermediate\_ca\_signed\_csr\_secret\_arn) | Secrets Manager ARN for the signed Consul intermediate CA certificate. |
| <a name="output_consul_security_group_id"></a> [consul\_security\_group\_id](#output\_consul\_security\_group\_id) | ID of the Consul cluster security group. |
| <a name="output_consul_snapshots_bucket"></a> [consul\_snapshots\_bucket](#output\_consul\_snapshots\_bucket) | S3 bucket for Consul snapshots. |
| <a name="output_consul_target_group_arn"></a> [consul\_target\_group\_arn](#output\_consul\_target\_group\_arn) | ARN of the Consul NLB target group. |
| <a name="output_consul_tls_ca_bundle_ssm_parameter_name"></a> [consul\_tls\_ca\_bundle\_ssm\_parameter\_name](#output\_consul\_tls\_ca\_bundle\_ssm\_parameter\_name) | SSM parameter name for the Consul PKI TLS CA bundle. |
| <a name="output_consul_url"></a> [consul\_url](#output\_consul\_url) | URL of the Consul cluster. |
| <a name="output_consul_version"></a> [consul\_version](#output\_consul\_version) | Consul Enterprise version deployed. |
| <a name="output_ec2_ami_name"></a> [ec2\_ami\_name](#output\_ec2\_ami\_name) | Name of the AMI used for EC2 instances. |
<!-- END_TF_DOCS -->
