#variable "public_key_path" {
#  description = "Path to the public key file."
#  type        = string
#  default     = "/var/lib/jenkins/.ssh/id_rsa.pub"
#}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}





