provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Main VPC"
  }
}

# Create a Subnet within the VPC
resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Main Subnet"
  }
}

# Create a Security Group within the VPC
resource "aws_security_group" "ec2_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "ec2_sg"
  description = "Allow SSH and HTTP"

  # Allow SSH only from Jenkins IP (replace <YOUR_JENKINS_IP> with your Jenkins server IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["54.244.39.147/32"]
  }

  # HTTP remains open to the world; consider limiting this in a production environment
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2_SG_BY_JENKINS"
  }
}

# Create the EC2 instance within the VPC and subnet
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0261755bbcb8c4a84" # Make sure this AMI is available in your region
  instance_type = "t2.large"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = "sec_com_ass_key_pair" # Ensure this key pair exists in AWS and the private key is on Jenkins

  tags = {
    Name = "EC2_INSTANCE_BY_JENKINS"
  }
}

# Output the public IP of the instance
output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
