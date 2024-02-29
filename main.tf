resource "aws_vpc" "vpc-hw2" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "hw2-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "pub_subnet_1a" {
  vpc_id                  = aws_vpc.vpc-hw2.id
  cidr_block              = "10.0.0.0/17"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "1a-public_subnet"

  }
}

resource "aws_subnet" "pub_subnet_1b" {
  vpc_id                  = aws_vpc.vpc-hw2.id
  cidr_block              = "10.0.128.0/18"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "1b-public_subnet"
  }
}

resource "aws_subnet" "priv_subnet_1a" {
  vpc_id                  = aws_vpc.vpc-hw2.id
  cidr_block              = "10.0.192.0/19"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false


  tags = {
    Name = "1a-private"
  }

}


resource "aws_subnet" "priv_subnet_1b" {
  vpc_id                  = aws_vpc.vpc-hw2.id
  cidr_block              = "10.0.224.0/19"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false


  tags = {
    Name = "1b-private"
  }

}

resource "aws_internet_gateway" "igw_hw2" {
  vpc_id = aws_vpc.vpc-hw2.id

  tags = {
    Name = "igw"
  }
}


resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "eip"
  }

}
resource "aws_nat_gateway" "NAT-gw-hw2" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.priv_subnet_1b.id

  tags = {
    Name = "gw NAT"
  }
}


resource "aws_route_table" "rout_table" {
  vpc_id = aws_vpc.vpc-hw2.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_hw2.id
  }
  tags = {
    Name = "rout-table-public"
  }
}


resource "aws_route_table_association" "pub-1a" {
  subnet_id      = aws_subnet.pub_subnet_1a.id
  route_table_id = aws_route_table.rout_table.id
}

resource "aws_route_table_association" "pub-1b" {
  subnet_id      = aws_subnet.pub_subnet_1b.id
  route_table_id = aws_route_table.rout_table.id
}



resource "aws_route_table" "rout_table-private" {
  vpc_id = aws_vpc.vpc-hw2.id


  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT-gw-hw2.id
  }

  tags = {
    Name = "rout-table-private"
  }
}


resource "aws_route_table_association" "priv_subnet_1a" {
  subnet_id      = aws_subnet.priv_subnet_1a.id
  route_table_id = aws_route_table.rout_table-private.id
}

resource "aws_route_table_association" "priv_subnet_1b" {
  subnet_id      = aws_subnet.priv_subnet_1b.id
  route_table_id = aws_route_table.rout_table-private.id
}


data "aws_key_pair" "ssh_key" {
  key_name = "tentek"

}


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*x86_64-gp2"]
  }
}
output "amazon_linux_2" {
  value = data.aws_ami.amazon_linux_2.id

}

resource "aws_security_group" "public_ec2_sgrp" {
  name        = "public_ec2_sgrp"
  description = "public_ec2_sgrp"
  vpc_id      = aws_vpc.vpc-hw2.id

  tags = {
    Name = "public_ec2_sgrp"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.public_ec2_sgrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.public_ec2_sgrp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.public_ec2_sgrp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_instance" "pub_1a_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.pub_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.public_ec2_sgrp.id]
  key_name               = data.aws_key_pair.ssh_key.key_name
  user_data              = <<EOF
  #!bin/bash
  yum update -y
  yum install httpd  -y
  systemctl start httpd
  systemctl enable httpd 
  echo "<h1>This is my $(hostname -f) instnace </h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "public-1a-insatnce"
  }
}

resource "aws_instance" "pub_1b_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.pub_subnet_1b.id
  vpc_security_group_ids = [aws_security_group.public_ec2_sgrp.id]
  key_name               = data.aws_key_pair.ssh_key.key_name
  user_data              = file("userdate.sh")

  tags = {
    Name = "public-1b-insatnce"
  }
}
