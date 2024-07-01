
resource "aws_vpc" "PR1_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "publicsub1" {
  vpc_id                  = aws_vpc.PR1_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "PR1_IGW" {
  vpc_id = aws_vpc.PR1_vpc.id
}

resource "aws_internet_gateway_attachment" "example" {
  internet_gateway_id = aws_internet_gateway.PR1_IGW.id
  vpc_id              = aws_vpc.PR1_vpc.id
}

resource "aws_route_table" "PR1_RT" {
  vpc_id = aws_vpc.PR1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.PR1_IGW.id
  }
}

resource "aws_route_table_association" "PR1_rta1" {
  route_table_id = aws_route_table.PR1_RT.id
  subnet_id      = aws_subnet.publicsub2.id
}


resource "aws_security_group" "PR1_SG" {
  name        = "web-sg"
  description = "Security group for project1"
  vpc_id      = aws_vpc.PR1_vpc.id
}

resource "aws_security_group_rule" "HTTP" {
  type              = "ingress"
  description       = "HTTP from web"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.PR1_SG.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "SSH" {
  type              = "ingress"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.PR1_SG.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "example" {
  security_group_id = aws_security_group.PR1_SG.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_key_pair" "PR1_KP" {
  key_name   = "Webserver-KP"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "PR1_WebServer1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.publicsub1.id
  vpc_security_group_ids = [aws_security_group.PR1_SG.id]
  key_name               = aws_key_pair.PR1_KP.key_name

  /*user_data = <<-EOL
  #!/bin/bash -xe

  sudo apt update
  sudo apt install apache2 --yes
  echo "This is Web Server 1" >> /var/www/html
  EOL*/

}


resource "aws_instance" "PR1_WebServer2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.publicsub2.id
  vpc_security_group_ids = [aws_security_group.PR1_SG.id]
  key_name               = aws_key_pair.PR1_KP.key_name

  /*user_data = <<-EOL
  #!/bin/bash -xe

  sudo apt update
  sudo apt install apache2 --yes
  echo "This is Web Server 1" >> /var/www/html
  EOL*/
}

#Application Load balancer


