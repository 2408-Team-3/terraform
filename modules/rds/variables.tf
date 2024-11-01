# VPC ID for the security group to be created in
#value is passed in via the module block in the root main.tf

variable "vpc_id" {
  description = "The ID of the VPC in which to create the RDS resources"
  type        = string
}

# Subnet IDs for the database subnet group
#value is passed in via the module block in the root main.tf

variable "db_subnet_ids" {
  description = "A list of subnet IDs for the RDS subnet group"
  type        = list(string)
}

# Database Secret Name in AWS Secrets Manager
variable "db_secret_name" {
  description = "The name of the AWS Secrets Manager secret containing RDS credentials"
  type        = string
  default     = "flytrap_db_credentials"
}

variable "db_name" {
  description = "The name of the database to connect to"
  type        = string
  default = "flytrap_db"
}