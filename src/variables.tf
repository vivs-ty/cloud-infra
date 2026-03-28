variable "aws_region" {
  description = "AWS region used for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Prefix for the application S3 bucket name. Terraform appends a unique suffix on first create."
  type        = string
}

variable "ssh_ingress_cidrs" {
  description = "CIDR ranges allowed to reach the instance over SSH"
  type        = list(string)
}