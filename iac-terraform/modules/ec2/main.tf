locals {
  name = "${var.project}-web"
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "web" {
  name        = "${local.name}-sg"
  description = "Allow SSH(22) from allowed CIDR; HTTP(80) from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-sg" }
}

# Simple web server via user-data
data "template_cloudinit_config" "userdata" {
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOT
      #!/bin/bash
      dnf -y update
      dnf -y install nginx
      echo "<h1>${local.name} — Hello from Terraform</h1>" > /usr/share/nginx/html/index.html
      systemctl enable nginx
      systemctl start nginx
    EOT
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = data.template_cloudinit_config.userdata.rendered

  tags = { Name = local.name }
}
