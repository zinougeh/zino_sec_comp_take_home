provider "aws" {
  region = "us-west-2"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

resource "aws_key_pair" "deployer" {
  key_name   = "sec_com_ass_key_pair"
  public_key = var.ssh_public_key
}

# Assuming VPC exists, no changes made to VPC resource definition

resource "aws_security_group" "allow_ssh_and_http" {
  name        = "allow_ssh_and_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = "vpc-0b2b089d46f9cbb7d" # Direct VPC ID used

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
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_http.id]
  subnet_id              = "sec_comp_subnet"  # Use the existing subnet ID here
  user_data              = templatefile("${path.module}/user_data.sh", { ssh_public_key = file(var.public_key_path) })

  tags = {
    Name = "MicroK8s-Instance"
  }
}

resource "aws_eip" "eip_alloc" {
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "EC2 EIP"
  }
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = "vpc-0b2b089d46f9cbb7d" # Direct VPC ID used
  tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = "vpc-0b2b089d46f9cbb7d" # Direct VPC ID used
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  tags = {
    Name = "Main Route Table"
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.route_table.id
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
