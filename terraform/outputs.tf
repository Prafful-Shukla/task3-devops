output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "ec2_instance_id" {
  value = aws_instance.app.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_secret_name" {
  value = aws_secretsmanager_secret.rds.name
}
