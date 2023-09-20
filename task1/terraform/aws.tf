provider "aws" {
  region = "us-west-2"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  default     = ""  
}

locals {
  vpc_id = "vpc-0b2b089d46f9cbb7d"
}

resource "aws_security_group" "allow_ssh_and_http" {
  name        = "sec_comp_allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                   = "ami-0c65adc9a5c1b5d7c"
  instance_type         = "t2.large"
  key_name              = "sec_com_ass_key_pair"
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_http.id]
  subnet_id              = "subnet-07752613538db1a9b"
  user_data              = templatefile("${path.module}/user_data.sh", { ssh_public_key = var.ssh_public_key })

  tags = {
    Name = "MicroK8s-Instance"
  }

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/user_data.sh"
  }
}

resource "aws_eip" "eip_alloc" {
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "EC2 EIP"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.eip_alloc.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.ec2_instance.private_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.ec2_instance.public_dns
}
