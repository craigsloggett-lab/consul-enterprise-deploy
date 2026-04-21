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
