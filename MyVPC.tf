terraform {
  required_version = ">= 1.5.0"  # 최소 Terraform 버전 1.5.0 이상
}

provider "aws" {}

# VPC 생성
resource "aws_vpc" "Myvpc" {
  cidr_block = "20.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "MyPublicSN" {
  vpc_id                  = aws_vpc.Myvpc.id
  cidr_block              = "20.40.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "My-Public-SN"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "MyIGW" {
  vpc_id = aws_vpc.Myvpc.id
  tags = {
    Name = "My-IGW"
  }
}

# Public Route Table 생성
resource "aws_route_table" "MyPublicRT" {
  vpc_id = aws_vpc.Myvpc.id
  tags = {
    Name = "MyPublicRT"
  }
}

# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.MyPublicRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.MyIGW.id
}

# Public Subnet에 Public Route Table 연결
resource "aws_route_table_association" "MyPublicSN" {
  subnet_id      = aws_subnet.MyPublicSN.id
  route_table_id = aws_route_table.MyPublicRT.id
}

# Security Group for Public Subnet
resource "aws_security_group" "MySG" {
  vpc_id = aws_vpc.Myvpc.id
  name   = "MySG"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 접근을 위해 모든 IP 허용
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 접근을 위해 모든 IP 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NACL 생성 (Public Subnet용)
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.Myvpc.id
  tags = {
    Name = "public-acl"
  }
}

# NACL 규칙 추가 (Public Subnet용)
resource "aws_network_acl_rule" "public_acl_allow_inbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_acl_allow_outbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

# EC2 인스턴스 (Public Subnet)
resource "aws_instance" "MyEC2" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2023 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.MyPublicSN.id
  vpc_security_group_ids = [aws_security_group.MySG.id]
  associate_public_ip_address = true
  key_name = "my-keypair-01"
  tags = {
    Name = "MyEC2"
  }
}
