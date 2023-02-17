terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

#Ask the this variable value while terraform apply.
variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  region     = "us-west-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Generating key pair to connect instance.
resource "tls_private_key" "rsa-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "local-key" {
  content  = tls_private_key.rsa-key.private_key_pem
  filename = "aws.pem"
}

resource "aws_key_pair" "keypair" {
  key_name   = "aws"
  public_key = tls_private_key.rsa-key.public_key_openssh
}

# Create security group to allow port 80 and 22
resource "aws_security_group" "allow_http" {
  name        = "http-allow"
  description = "terraform allow"

  ingress {
    description      = "for http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "for ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "http"
    from_port        = 80
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    to_port          = 80
  }

  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "ssh"
    from_port        = 22
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    to_port          = 22
  }
}


# create an instance
resource "aws_instance" "terra-vm" {
  ami             = "ami-04bad3c587fe60d89"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_http.name]
  key_name        = aws_key_pair.keypair.key_name #this is key pair name

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa-key.private_key_pem  #path of pem file
    host        = aws_instance.terra1.public_ip
  }

  provisioner "file" {
    source      = "my-script.sh"
    destination = "./my-script.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ./my-script.sh",
      "sudo ./my-script.sh"
    ]
  }


}

output "ec2_ip" {
  value = aws_instance.terra1.public_ip
}
