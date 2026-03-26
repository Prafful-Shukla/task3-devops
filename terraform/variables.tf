//inputs 
variable "db_username" {
  default = "postgres"
}

variable "db_password" {
  description = "Database password"
  sensitive   = true
}

variable "key_name" {
  default = "task3-key"
}