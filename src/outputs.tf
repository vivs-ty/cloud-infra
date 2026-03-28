output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.bucket_name
}