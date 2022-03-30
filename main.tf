# create a vpc
resource "aws_vpc" "custom-vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = var.instance_tenancy

  tags = {
    Name = var.vpc_name
  }
}

#create a public and private subnet in custom vpc
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.custom-vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.public_subnet_az
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.custom-vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-south-1b"
  tags = {
    Name = var.private_subnet_name
  }
}

#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom-vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

#create a route table for public subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = var.public_route_table_name
  }
}

#association of public subnet to this route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
}

# #create an elastic ip for nat gateway
resource "aws_eip" "nateIP" {
  vpc = true
  depends_on = [
    aws_internet_gateway.gw
  ]
}

# #create internet gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nateIP.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = var.nat_gateway_name
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.custom-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = var.private_route_table_name
  }
}

#association of public subnet to this route table
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-route-table.id
}
# create a security group
resource "aws_security_group" "security-group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.custom-vpc.id
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_name # Create "Key" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./my-terraform-key.pem"
  }
}

resource "aws_instance" "public-instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public-subnet.id
  availability_zone           = var.public_subnet_az
  vpc_security_group_ids      = [aws_security_group.security-group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.kp.key_name
  tags = {
    Name = var.vmname_public
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/my-terraform-key.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/my-terraform-key.pem"
    destination = "/home/ec2-user/my-terraform-key.pem"
  }

  provisioner "remote-exec" {
    inline = [
        "chmod 400 /home/ec2-user/my-terraform-key.pem"
    ]
  }

}

resource "aws_instance" "private-instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private-subnet.id
  availability_zone           = var.private_subnet_az
  vpc_security_group_ids      = [aws_security_group.security-group.id]
  key_name                    = aws_key_pair.kp.key_name
  associate_public_ip_address = false
  tags = {
    Name = var.vmname_private
  }
}