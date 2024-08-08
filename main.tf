# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.range
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc
  }
}

# Create a public subnet
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr-1
  availability_zone = var.az-1
  map_public_ip_on_launch = true
  tags = {
    Name = var.pub-sub-1
  }
}
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr-2
  availability_zone = var.az-2
  map_public_ip_on_launch = true
  tags = {
    Name = var.pub-sub-2
  }
}

# Create a private subnet
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr-3
  availability_zone = var.az-2
  tags = {
    Name = var.pri-sub-1
  }
}
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr-4
  availability_zone = var.az-3
  tags = {
    Name = var.pri-sub-2
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.ig-gate
  }
}

# Create a route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.pub-route
  }
}
resource "aws_route_table_association" "public_1" {
    subnet_id      = aws_subnet.public_1.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
    subnet_id      = aws_subnet.public_2.id
    route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = var.pri-route
  }
}
# Associate the public subnet with the public route table
resource "aws_route_table_association" "private_1" {
    subnet_id      = aws_subnet.private_1.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
    subnet_id      = aws_subnet.private_2.id
    route_table_id = aws_route_table.private.id
}
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.gw]
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "my-nat-gateway"
  }
}

resource "aws_route" "internet_route" {
    route_table_id         = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw.id
}
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "instance-sg"
  }
}
resource "aws_instance" "vm_1" {
ami=var.ami
instance_type=var.insta
key_name=var.key
subnet_id=aws_subnet.public_1.id
vpc_security_group_ids  = [aws_security_group.instance_sg.name]
associate_public_ip_address = true
tags={
    name="dev"
}

}
resource "aws_instance" "vm_2" {
ami=var.ami
instance_type=var.insta
key_name=var.key
subnet_id     = aws_subnet.private_1.id
vpc_security_group_ids = [aws_security_group.web.id]
associate_public_ip_address = false
tags={
    name="producion"
}
connection {
        type        = "ssh"
        host        = self.private_ip
        user        = "ubuntu"
        private_key = file("/home/ubuntu/new.pem")
        timeout     = "4m"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt update",
            "sudo apt install apache2 -y",
            "sudo rm -rf /var/www/html/*",
            "echo 'this is server-1' | sudo tee /var/www/html/index.html",
            "sudo systemctl restart apache2",
        ]
    }
}
resource "aws_instance" "vm_3" {
ami=var.ami
instance_type=var.insta
key_name=var.key
subnet_id     = aws_subnet.private_2.id
vpc_security_group_ids = [aws_security_group.web.id]
associate_public_ip_address = false
tags={
    name="production"
}
connection {
        type        = "ssh"
        host        = self.private_ip
        user        = "ubuntu"
        private_key = file("/home/ubuntu/new.pem")
        timeout     = "4m"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt update",
            "sudo apt install apache2 -y",
            "sudo rm -rf /var/www/html/*",
            "echo 'this is server-2' | sudo tee /var/www/html/index.html",
            "sudo systemctl restart apache2",
        ]
    }
}
