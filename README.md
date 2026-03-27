# Task3 DevOps Project

This repo contains a simple full-stack app with Docker, plus Terraform for AWS (EC2 + RDS). It is set up so you can:
1) keep secrets out of GitHub, and
2) clone on an EC2 instance and run with Docker.

It now also includes:
- GitHub Actions CI for Docker + Terraform validation
- GitHub Actions CD for infrastructure apply + EC2 deployment
- AWS Secrets Manager for the live database connection details
- AWS Systems Manager based deployments so you do not need SSH open on the EC2 instance

## Repo Structure
- `frontend/` React frontend
- `backend/` API backend
- `nginx/` reverse proxy config
- `docker-compose.yml` docker services
- `terraform/` AWS infrastructure (state and secrets excluded)
- `terraform/bootstrap/` one-time remote-state bootstrap
- `.github/workflows/` CI/CD pipelines
- `scripts/` helper scripts used by the deployment workflow

## Safety (What Is NOT Committed)
- `.env` and any `*.env`
- `terraform/terraform.tfvars`
- `terraform/*.tfstate*`
- `terraform/.terraform/`

Templates are provided:
- `.env.example`
- `terraform/terraform.tfvars.example`

## Local Run
1. Create your local environment file:
   ```bash
   cp .env.example .env
   ```

2. For local Docker runs, set the direct DB values in `.env`:
   ```bash
   DB_HOST=your-rds-endpoint.amazonaws.com
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=change_me
   DB_NAME=postgres
   DB_SSL=false
   ```

3. Start the app:
   ```bash
   docker compose up -d --build
   ```

The backend will use `DB_*` values when they are present. In AWS, it will use `SECRET_ID` and `AWS_REGION` and fetch the credentials from Secrets Manager.

## One-Time AWS Bootstrap
The deployment workflow expects Terraform remote state in S3 plus DynamoDB locking.

1. Bootstrap the state backend:
   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply \
     -var="state_bucket_name=YOUR_UNIQUE_STATE_BUCKET" \
     -var="lock_table_name=task3-terraform-locks"
   ```

2. Configure the main Terraform project locally once:
   ```bash
   cd ../
   terraform init -backend-config="bucket=YOUR_UNIQUE_STATE_BUCKET" \
     -backend-config="key=task3/terraform.tfstate" \
     -backend-config="region=us-east-1" \
     -backend-config="dynamodb_table=task3-terraform-locks"
   ```

3. Apply the infrastructure once locally if you want to create the first EC2/RDS resources before handing future changes to GitHub Actions:
   ```bash
   terraform apply
   ```

## GitHub Actions Setup
The CD workflow uses GitHub OIDC to assume an AWS role instead of storing long-lived AWS access keys.

1. Create or reuse an IAM role in AWS that trusts GitHub's OIDC provider and allows:
   - Terraform operations for the resources in `terraform/`
   - `ssm:SendCommand`, `ssm:GetCommandInvocation`, and `ssm:DescribeInstanceInformation`
   - `ec2:DescribeInstances`
   - S3 + DynamoDB access to the Terraform state backend

   Example trust policy for the `main` branch of this repo:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_OWNER/YOUR_REPO:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```

2. In GitHub, add this repository secret:
   - `AWS_ROLE_TO_ASSUME`: the ARN of the deploy role

3. In GitHub, add these repository variables:
   - `AWS_REGION`: usually `us-east-1`
   - `TF_STATE_BUCKET`: the S3 bucket created by `terraform/bootstrap`
   - `TF_STATE_LOCK_TABLE`: the DynamoDB table created by `terraform/bootstrap`
   - `TF_STATE_KEY`: optional, defaults to `task3/terraform.tfstate`
   - `APP_REPOSITORY_URL`: optional. Set this only if the repo is private or you want the EC2 instance to clone from a custom URL.

4. Push to `main` or run the `Deploy` workflow manually.

## Deployment Flow
1. GitHub Actions validates the backend, Docker Compose file, and Terraform on pull requests and branch pushes.
2. On `main`, GitHub Actions assumes the AWS deploy role with OIDC.
3. Terraform applies the infrastructure and stores the database connection details in AWS Secrets Manager.
4. The EC2 instance uses its IAM role to read the secret at runtime.
5. GitHub Actions deploys through AWS Systems Manager, writes `.env` with `SECRET_ID` and `AWS_REGION`, and runs `docker-compose up -d --build` on the instance.

## Notes
- Do not commit real secrets. Only commit the `*.example` files.
- The EC2 security group now exposes only port `80`. Deployment and access are intended to go through AWS Systems Manager instead of SSH.
- If you run Terraform locally for validation only, use `terraform init -backend=false` inside `terraform/`.
