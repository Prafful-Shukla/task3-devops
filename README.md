# Task3 DevOps Project

This repo contains a simple full-stack app with Docker, plus Terraform for AWS (EC2 + RDS). It is set up so you can:
1) keep secrets out of GitHub, and
2) clone on an EC2 instance and run with Docker.

## Repo Structure
- `frontend/` React frontend
- `backend/` API backend
- `nginx/` reverse proxy config
- `docker-compose.yml` docker services
- `terraform/` AWS infrastructure (state and secrets excluded)

## Safety (What Is NOT Committed)
- `.env` and any `*.env`
- `terraform/terraform.tfvars`
- `terraform/*.tfstate*`
- `terraform/.terraform/`

Templates are provided:
- `.env.example`
- `terraform/terraform.tfvars.example`

## Quick Start (EC2)
1. Clone the repo on your EC2 instance:
   ```bash
   git clone https://github.com/Prafful-Shukla/task3-devops.git
   cd task3-devops
   ```

2. Create your environment file:
   ```bash
   cp .env.example .env
   # edit .env with your real RDS values
   ```

3. (If needed) create your Terraform vars file locally:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # edit terraform/terraform.tfvars with a strong db_password
   ```

4. Run Terraform (if you want to create/update infra from here):
   ```bash
   cd terraform
   terraform init
   terraform apply
   cd ..
   ```

5. Run the app with Docker:
   ```bash
   docker compose up -d --build
   ```

## Notes
- Do not commit real secrets. Only commit the `*.example` files.
- If you already have infra, you can skip the Terraform steps and just set `.env` and run Docker.
