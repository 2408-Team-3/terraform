output "flytrap_db_endpoint" {
  value       = aws_db_instance.flytrap_db.endpoint
  description = "The connection endpoint for the Flytrap RDS database"
}

# get rid of it (it's referencing db_name)  - use variables
output "flytrap_db_name" {
  value       = aws_db_instance.flytrap_db.db_name
  description = "The name of the Flytrap RDS database"
}

output "flytrap_db_sg_id" {
  value       = aws_security_group.flytrap_db_sg.id
  description = "The security group ID for the Flytrap RDS instance"
}

# get rid of it (it's referencing db_name) - use variables
output "flytrap_db_subnet_group" {
  value       = aws_db_subnet_group.flytrap_db_subnet_group.name
  description = "The DB subnet group used by Flytrap RDS"
}