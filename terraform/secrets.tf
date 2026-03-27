resource "aws_secretsmanager_secret" "rds" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    username = var.db_username
    password = local.effective_db_password
    dbname   = var.db_name
  })
}
