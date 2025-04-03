# VPC 생성
resource "aws_vpc" "ELB_VPC" {
  cidr_block = "10.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "ELB-VPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "ELBPublicSN1" {
  vpc_id                  = aws_vpc.ELB_VPC.id
  cidr_block              = "10.40.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ELB-Public-SN1"
  }
}

resource "aws_subnet" "ELBPublicSN2" {
  vpc_id                  = aws_vpc.ELB_VPC.id
  cidr_block              = "10.40.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "ELB-Public-SN2"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "ELB_IGW" {
  vpc_id = aws_vpc.ELB_VPC.id
  tags = {
    Name = "ELB-IGW"
  }
}

# Public Route Table 생성
resource "aws_route_table" "ELBPublicRT" {
  vpc_id = aws_vpc.ELB_VPC.id
  tags = {
    Name = "ELBPublicRT"
  }
}

# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "ELB_internet" {
  route_table_id         = aws_route_table.ELBPublicRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ELB_IGW.id
}

# Public Subnet에 Public Route Table 연결
resource "aws_route_table_association" "ELBPublicSN1" {
  subnet_id      = aws_subnet.ELBPublicSN1.id
  route_table_id = aws_route_table.ELBPublicRT.id
}

resource "aws_route_table_association" "ELBPublicSN2" {
  subnet_id      = aws_subnet.ELBPublicSN2.id
  route_table_id = aws_route_table.ELBPublicRT.id
}

# Security Group for Public Subnet
resource "aws_security_group" "ELBSG" {
  vpc_id = aws_vpc.ELB_VPC.id
  name   = "ELBSG"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 접근을 위해 모든 IP 허용
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 접근을 위해 모든 IP 허용
  }
  ingress {
    from_port   = 161
    to_port     = 161
    protocol    = "udp"
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
resource "aws_network_acl" "ELB_public_acl" {
  vpc_id = aws_vpc.ELB_VPC.id
  tags = {
    Name = "ELB_public-acl"
  }
}

# NACL 규칙 추가 (Public Subnet용)
resource "aws_network_acl_rule" "ELB_public_acl_allow_inbound" {
  network_acl_id = aws_network_acl.ELB_public_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "ELB_public_acl_allow_outbound" {
  network_acl_id = aws_network_acl.ELB_public_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

# EC2 인스턴스 (Public Subnet)
resource "aws_instance" "SERVER_1" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2023 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ELBPublicSN1.id
  vpc_security_group_ids = [aws_security_group.ELBSG.id]
  associate_public_ip_address = true
  key_name = "ServerKey_01"
  tags = {
    Name = "SERVER-1"
  }
}

resource "aws_instance" "SERVER_2" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2023 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ELBPublicSN2.id
  vpc_security_group_ids = [aws_security_group.ELBSG.id]
  associate_public_ip_address = true
  key_name = "ServerKey_02"
  tags = {
    Name = "SERVER-2"
  }
}

resource "aws_instance" "SERVER_3" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2023 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ELBPublicSN2.id
  vpc_security_group_ids = [aws_security_group.ELBSG.id]
  associate_public_ip_address = true
  key_name = "ServerKey_02"
  tags = {
    Name = "SERVER-3"
  }
}
