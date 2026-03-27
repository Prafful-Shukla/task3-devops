variable "aws_region" {
  description = "AWS region used for the infrastructure and application."
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Optional override for the database password. Leave null to auto-generate one."
  type        = string
  sensitive   = true
  default     = null
}

variable "db_name" {
  description = "Database name stored in the secret and used by the app."
  type        = string
  default     = "postgres"
}

variable "secret_name" {
  description = "Secrets Manager name that stores the RDS connection details."
  type        = string
  default     = "task3/rds/postgres"
}
