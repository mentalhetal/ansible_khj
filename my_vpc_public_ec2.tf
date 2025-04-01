terraform {
  required_version = ">= 1.5.0"  # 최소 Terraform 버전 1.5.0 이상
}

provider "aws" { 
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone        = "ap-northeast-2a"
  map_public_ip_on_launch = true  # 공인 IP 할당 여부
  tags = {
    Name = "my-subnet"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-route-table"
  }
}

resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  tags = {
    Name = "my-sg"
  }
}

resource "aws_network_acl" "my_nacl" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    rule_no    = 100
    protocol   = "6"
    action = "allow"   #(주의)명령어 변경되어짐
    cidr_block = "0.0.0.0/0"
    from_port  = 0  # 모든 포트 허용
    to_port    = 0  # 모든 포트 허용
  }

  egress {
    rule_no    = 100
    protocol   = "6"
    action = "allow"    #(주의)명령어 변경되어짐
    cidr_block = "0.0.0.0/0"
    from_port  = 0  # 모든 포트 허용
    to_port    = 0  # 모든 포트 허용
  }

  tags = {
    Name = "my-nacl"
  }
}

resource "aws_instance" "my_ec2" {
        ami = "ami-070e986143a3041b6"
        instance_type = "t2.micro"
        subnet_id = aws_subnet.my_subnet.id
        vpc_security_group_ids = [aws_security_group.my_sg.id]
        key_name = "my-keypair-01"

        user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd

                # IMDSv2를 사용하여 인스턴스 ID 가져오기
                TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
                INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

                # index.html 생성
                echo "<html><body><h1>My EC2 Instance: $INSTANCE_ID</h1></body></html>" > /var/www/html/index.html
                EOF

        tags = {
                Name = "my-ec2-instance"
        }
}
