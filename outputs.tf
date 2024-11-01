# these are here for testing. Ultimately, don't think they need to be accessible at the top level

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_ids
}

output "flytrap_db_endpoint" {
  value       = module.rds.flytrap_db_endpoint
  description = "The connection endpoint for the Flytrap RDS database"
}

output "flytrap_db_name" {
  value       = module.rds.flytrap_db_name
  description = "The name of the Flytrap RDS database"
}

output "flytrap_db_security_group_id" {
  value       = module.rds.flytrap_db_sg_id
  description = "The security group ID for the Flytrap RDS instance"
}

output "flytrap_db_subnet_group" {
  value       = module.rds.flytrap_db_subnet_group
  description = "The DB subnet group used by Flytrap RDS"
}