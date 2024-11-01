terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">=1.0"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
}

module "rds" {
  source        = "./modules/rds"
  vpc_id        = module.vpc.vpc_id             # references vpc output
  db_subnet_ids = module.vpc.private_subnet_ids # references vpc output
}