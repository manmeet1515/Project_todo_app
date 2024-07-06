
resource "aws_vpc" "Project_vpc" {
  cidr_block = "10.20.0.0/16"
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.Project_vpc.id
  cidr_block              = "10.20.10.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "Project_IGW" {
  vpc_id = aws_vpc.Project_vpc.id
}

resource "aws_internet_gateway_attachment" "example" {
  internet_gateway_id = aws_internet_gateway.Project_IGW.id
  vpc_id              = aws_vpc.Project_vpc.id
}

resource "aws_route_table" "Project_RT" {
  vpc_id = aws_vpc.Project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Project_IGW.id
  }
}

resource "aws_route_table_association" "PR_rt" {
  route_table_id = aws_route_table.Project_RT.id
  subnet_id      = aws_subnet.publicsubnet.id
}


resource "aws_security_group" "PR_SG" {
  name        = "web-sg"
  description = "Security group for todo app"
  vpc_id      = aws_vpc.Project_vpc.id
}

resource "aws_security_group_rule" "HTTP" {
  type              = "ingress"
  description       = "HTTP from web"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.PR_SG.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "SSH" {
  type              = "ingress"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.PR_SG.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "example" {
  security_group_id = aws_security_group.PR_SG.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_key_pair" "PR_KP" {
  key_name   = "Webserver-KP"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "App_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.publicsubnet.id
  vpc_security_group_ids = [aws_security_group.PR_SG.id]
  key_name               = aws_key_pair.PR_KP.key_name

  /*user_data = <<-EOL
  #!/bin/bash -xe

  sudo apt update -y
  sudo apt install docker -y
  sudo usermod -a -G docker ec2-user
  EOL*/

}




