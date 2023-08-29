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

  tags = {
    Name = "EC2_SG_BY_JENKINS"
  }
}

# Create the EC2 instance within the VPC and subnet
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0261755bbcb8c4a84"
  instance_type = "t2.large"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = "sec_com_ass_key_pair"

  tags = {
    Name = "EC2_INSTANCE_BY_JENKINS"
  }
}

# Output the public IP of the instance
output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
