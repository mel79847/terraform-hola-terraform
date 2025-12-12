############################
# DATA SOURCE: AMI Ubuntu  #
############################

data "aws_ami" "ubuntu" {
  most_recent = true

  # Owner oficial de Ubuntu en AWS
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# RED: VPC + SUBNET + IGW  #
############################

resource "aws_vpc" "upb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "upb-vpc-hola-terraform"
  }
}

resource "aws_internet_gateway" "upb_igw" {
  vpc_id = aws_vpc.upb_vpc.id

  tags = {
    Name = "upb-igw-hola-terraform"
  }
}

resource "aws_subnet" "upb_public_subnet" {
  vpc_id                  = aws_vpc.upb_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "upb-public-subnet-hola-terraform"
  }
}

resource "aws_route_table" "upb_public_rt" {
  vpc_id = aws_vpc.upb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.upb_igw.id
  }

  tags = {
    Name = "upb-public-rt-hola-terraform"
  }
}

resource "aws_route_table_association" "upb_public_rt_assoc" {
  subnet_id      = aws_subnet.upb_public_subnet.id
  route_table_id = aws_route_table.upb_public_rt.id
}

###########################################
# SECURITY GROUP: abrir HTTP (puerto 80) #
###########################################

resource "aws_security_group" "hola_sg" {
  name        = "hola-terraform-sg"
  description = "Permitir HTTP desde internet"
  vpc_id      = aws_vpc.upb_vpc.id

  # Entrada: HTTP desde cualquier lado
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida: todo permitido
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "hola-terraform-sg"
  }
}

############################
# EC2: Hola desde Terraform
############################

resource "aws_instance" "hola_terraform" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" # o "t2.micro" si tu free tier lo permite

  subnet_id              = aws_subnet.upb_public_subnet.id
  vpc_security_group_ids = [aws_security_group.hola_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2

              # Borrar el index por defecto de Apache
              rm -f /var/www/html/index.html

              # Crear nuestro index super simple
              echo "Hola desde Terraform" > /var/www/html/index.html

              # Asegurar que Apache esté arriba
              systemctl restart apache2
              systemctl enable apache2
              EOF

  tags = {
    Name = "Hola-Desde-Terraform"
  }
}
