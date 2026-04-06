# terraform-root-module-template

A GitHub repository template for creating new Terraform root module.

## Usage

The following files require your attention immediately after creating a
repository from this template:

- [ ] .github/CODEOWNERS
- [ ] .github/dependabot.yml
- [ ] .github/workflows/lint.yml
- [ ] backend.tf
- [ ] README.md

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_consul"></a> [consul](#module\_consul) | git::https://github.com/craigsloggett/terraform-aws-consul-enterprise | v0.6.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_consul_api_allowed_cidrs"></a> [consul\_api\_allowed\_cidrs](#input\_consul\_api\_allowed\_cidrs) | CIDR blocks allowed to reach the Consul API (port 8501) from outside the VPC. Only effective when nlb\_internal is false. | `list(string)` | `[]` | no |
| <a name="input_consul_license"></a> [consul\_license](#input\_consul\_license) | Consul Enterprise license string. | `string` | n/a | yes |
| <a name="input_ec2_ami_name"></a> [ec2\_ami\_name](#input\_ec2\_ami\_name) | Name filter for the AMI (supports wildcards). | `string` | n/a | yes |
| <a name="input_ec2_ami_owner"></a> [ec2\_ami\_owner](#input\_ec2\_ami\_owner) | AWS account ID of the AMI owner. | `string` | n/a | yes |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | Name of an existing EC2 key pair for SSH access. | `string` | n/a | yes |
| <a name="input_nlb_internal"></a> [nlb\_internal](#input\_nlb\_internal) | Whether the NLB is internal. | `bool` | `true` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name prefix for all resources. | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | Name of the existing Route 53 hosted zone. | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name tag of the existing VPC. | `string` | n/a | yes |

## Resources

| Name | Type |
|------|------|
| [aws_ami.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_route53_zone.consul](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | Public IP of the bastion host. |
| <a name="output_consul_ca_cert"></a> [consul\_ca\_cert](#output\_consul\_ca\_cert) | CA certificate for trusting the Consul TLS chain. |
| <a name="output_consul_ca_cert_secret_arn"></a> [consul\_ca\_cert\_secret\_arn](#output\_consul\_ca\_cert\_secret\_arn) | ARN of the Secrets Manager secret containing the Consul CA certificate. |
| <a name="output_consul_cluster_tag"></a> [consul\_cluster\_tag](#output\_consul\_cluster\_tag) | EC2 tag key and value used for Consul auto-join. |
| <a name="output_consul_datacenter"></a> [consul\_datacenter](#output\_consul\_datacenter) | Consul datacenter name. |
| <a name="output_consul_gossip_key_secret_arn"></a> [consul\_gossip\_key\_secret\_arn](#output\_consul\_gossip\_key\_secret\_arn) | ARN of the Secrets Manager secret containing the Consul gossip encryption key. |
| <a name="output_consul_private_ips"></a> [consul\_private\_ips](#output\_consul\_private\_ips) | Private IPs of the Consul nodes. |
| <a name="output_consul_security_group_id"></a> [consul\_security\_group\_id](#output\_consul\_security\_group\_id) | ID of the Consul cluster security group. |
| <a name="output_consul_target_group_arn"></a> [consul\_target\_group\_arn](#output\_consul\_target\_group\_arn) | ARN of the Consul NLB target group. |
| <a name="output_consul_token_secret_arn"></a> [consul\_token\_secret\_arn](#output\_consul\_token\_secret\_arn) | ARN of the Secrets Manager secret containing the Consul ACL token for Nomad. |
| <a name="output_consul_url"></a> [consul\_url](#output\_consul\_url) | URL of the Consul cluster. |
| <a name="output_ec2_ami_name"></a> [ec2\_ami\_name](#output\_ec2\_ami\_name) | Name of the AMI used for EC2 instances. |
| <a name="output_nomad_client_service_name"></a> [nomad\_client\_service\_name](#output\_nomad\_client\_service\_name) | Consul service name Nomad clients will register as. |
| <a name="output_nomad_server_service_name"></a> [nomad\_server\_service\_name](#output\_nomad\_server\_service\_name) | Consul service name Nomad servers will register as. |
| <a name="output_nomad_snapshot_service_name"></a> [nomad\_snapshot\_service\_name](#output\_nomad\_snapshot\_service\_name) | Consul service name the Nomad snapshot agent will register as. |
<!-- END_TF_DOCS -->
