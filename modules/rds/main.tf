resource "aws_db_subnet_group" "flytrap_db_subnet_group" {
  name       = "flytrap-db-subnet-group"
  subnet_ids = var.db_subnet_ids # the vpc's two private subnet ids; passed in via module block

  tags = {
    Name = "flytrap-db-subnet-group"
  }
}

resource "aws_security_group" "flytrap_db_sg" {
  name        = "flytrap-db-sg"
  description = "Allow access to the Flytrap database"
  vpc_id      = var.vpc_id

  # change cidr blocks after all modules run
  # ingress and egress should be the ec2 and lambda ips only

  # sets the inbound rule
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # change later, after EC2 and lambda are configured
  }

  # sets the outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"] # change later, after EC2 and lambda are configured
  }
}

# these use "data" because we've already created the resource via AWS CLI
# here we're just retrieving that data
# to reference these, prefix with 'data.'

# this retrieves the metadata
data "aws_secretsmanager_secret" "flytrap_db_secret" {
  name = var.db_secret_name
}

# this is the actual info; eg, if password changes, a new secret version is created

data "aws_secretsmanager_secret_version" "flytrap_db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.flytrap_db_secret.id
}

resource "aws_db_instance" "flytrap_db" {
  engine                 = "postgres"
  engine_version         = "16.3" # required AWS version
  instance_class         = "db.t3.micro"  # Free tier instance
  allocated_storage      = 20  # Minimum for PostgreSQL
  db_subnet_group_name   = aws_db_subnet_group.flytrap_db_subnet_group.name # defined above
  vpc_security_group_ids = [aws_security_group.flytrap_db_sg.id]  # vpc security group
  username               = jsondecode(data.aws_secretsmanager_secret_version.flytrap_db_secret_version.secret_string)["username"]
  password               = jsondecode(data.aws_secretsmanager_secret_version.flytrap_db_secret_version.secret_string)["password"]
  db_name                = var.db_name
  skip_final_snapshot    = true # change to false for production (makes a db backup)

  tags = {
    Name = "flytrap-db"
  }
}