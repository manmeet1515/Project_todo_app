
resource "aws_vpc" "Project_vpc" {
  cidr_block = "10.20.0.0/16"
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.Project_vpc.id
  cidr_block              = "10.20.10.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "Pro_IGW" {
  vpc_id = aws_vpc.Project_vpc.id
}

resource "aws_internet_gateway_attachment" "Attachment" {
  internet_gateway_id = aws_internet_gateway.Pro_IGW.id
  vpc_id              = aws_vpc.Project_vpc.id
}

resource "aws_route_table" "Project_RT" {
  vpc_id = aws_vpc.Project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Pro_IGW.id
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


resource "aws_key_pair" "Pro_KP" {
  key_name   = "Webserver-KP"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "App_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.publicsubnet.id
  vpc_security_group_ids = [aws_security_group.PR_SG.id]
  key_name               = aws_key_pair.Pro_KP.key_name
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  user_data = <<-EOL
  #!/bin/bash -xe
  sudo yum update -y
  sudo amazon-linux-extras install docker -y
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  EOL

}

resource "aws_ecr_repository" "Project_ECR" {
  name                 = "myapp_image"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Below resource configuration creates an IAM policy, IAM role, attaches policy
#to the role, and attaches the instance profile to the instance.

resource "aws_iam_policy" "ec2_ecr_policy" {
  name        = "Policy_for_EC2_to_access_ECR"
  path        = "/"
  description = "EC2 policy to access ECR"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:*",
          "cloudtrail:LookupEvents"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "replication.ecr.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}



resource "aws_iam_role" "ec2_ecr_role" {
  name = "Role_to_be_assumed_by_EC2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = aws_iam_policy.ec2_ecr_policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "Instance_profile_for_EC2_instance"
  role = aws_iam_role.ec2_ecr_role.name
}

output "ECR_arn" {
  value = aws_ecr_repository.Project_ECR.arn
}

output "ECR_url" {
  value = aws_ecr_repository.Project_ECR.repository_url
}

