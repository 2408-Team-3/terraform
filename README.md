To run:

1. Install Terraform by running the online quickstart tutorial

2. Install AWS CLI

3. Create a new secret for your RDS database credentials by running the following code snippet.
    -Update the secret-string to include your desired postgres username and password
    -Update the region to your AWS region

    aws secretsmanager create-secret
        --name flytrap_db_credentials
        --description "Credentials for Flytrap database"
        --secret-string '{"username":"dev_user", "password":"dev_password"}'
        --region us-east-1


4. Update any variables.tf files as needed. (AWS region and any desired changed to the
   default CIDR blocks).

5. Run `terraform init` and `terraform apply`.

6. Run`terraform destroy` to destroy the provisioned architecture.

