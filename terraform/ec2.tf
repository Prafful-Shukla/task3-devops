resource "aws_instance" "app" {
  ami           = "ami-053b0d53c279acc90" # Ubuntu 22.04 (us-east-1)
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name
  user_data              = templatefile("${path.module}/user_data.sh.tftpl", {})

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "task3-ec2"
  }
}
