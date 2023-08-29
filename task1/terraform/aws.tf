provider "aws" {
   region = "us-west-1"
}

variable "ssh_public_key" {
    description = "SSH Public Key"
    type        = string
    default     = ""
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Main VPC"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Main Subnet"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
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
  ami                   = "ami-09d95fab7fff3776c"  # Ubuntu Server 20.04 LTS
  instance_type         = "t2.large"
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.main_subnet.id
  user_data              = file("user_data.sh")
  tags = {
    Name = "MicroK8s-Instance"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "sec_com_ass_key_pair"
  public_key = var.ssh_public_key
}

resource "aws_eip" "eip_alloc" {
  instance = aws_instance.ec2_instance.id
  tags = {
    Name = "EC2_INSTANCE_EIP"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_vpc.main_vpc.main_route_table_id
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
