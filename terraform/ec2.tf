resource "aws_instance" "app" {
  ami           = "ami-053b0d53c279acc90" # Ubuntu 22.04 (us-east-1)
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  key_name = var.key_name

  tags = {
    Name = "task3-ec2"
  }
}