provider "aws" {
region = "us-east-1"
}

resource "aws_security_group" "ec2_sg" {
name = "ec2_sg"
description = "Allow SSH and HTTP"

ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_instance" "ec2_instance" {
ami = "ami-0261755bbcb8c4a84"
instance_type = "t2.large"
security_groups = [aws_security_group.ec2_sg.name]
associate_public_ip_address = true
key_name = "jenkins"

tags = {
Name = "EC2_INSTANCE_BY_JENKINS"
}
}

output "public_ip" {
value = aws_instance.ec2_instance.public_ip
}