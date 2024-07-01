
resource "aws_vpc" "PR1_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "publicsub1" {
  vpc_id                  = aws_vpc.PR1_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "publicsub2" {
  vpc_id                  = aws_vpc.PR1_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
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

resource "aws_route_table_association" "PR1_rta2" {
  route_table_id = aws_route_table.PR1_RT.id
  subnet_id      = aws_subnet.publicsub1.id
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

resource "aws_s3_bucket" "PR1" {
  bucket = "terraformbucket-test-456"

}

resource "aws_s3_bucket_public_access_block" "false" {
  bucket = aws_s3_bucket.PR1.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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


resource "aws_alb" "PR1_alb" {
  name               = "ProjectLB"
  load_balancer_type = "application"
  internal           = false
  security_groups = [ aws_security_group.PR1_SG.id ]

  subnet_mapping {
    subnet_id = aws_subnet.publicsub1.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.publicsub2.id
  }
}

# Target group

resource "aws_lb_target_group" "TG" {
  name     = "ProjectTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.PR1_vpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# Attaching ex2 instances to target groups

resource "aws_lb_target_group_attachment" "TGA1" {
  target_group_arn = aws_lb_target_group.TG.arn
  target_id        = aws_instance.PR1_WebServer1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "TGA2" {
  target_group_arn = aws_lb_target_group.TG.arn
  target_id        = aws_instance.PR1_WebServer2.id
  port             = 80
}

# Listener configuration

resource "aws_alb_listener" "Web" {
  load_balancer_arn = aws_alb.PR1_alb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG.arn

  }
}

output "LoadBalancerDNS" {
  value = aws_alb.PR1_alb.dns_name

}