resource "aws_vpc" "my" {
  cidr_block = "20.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MY-VPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "my" {
  vpc_id                  = aws_vpc.my.id
  cidr_block              = "20.40.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "MY-Public-SN"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "my" {
  vpc_id = aws_vpc.my.id
  tags = {
    Name = "MY-IGW"
  }
}

# Public Route Table 생성
resource "aws_route_table" "my" {
  vpc_id = aws_vpc.my.id
  tags = {
    Name = "MY-Public-RT"
  }
}

# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "internet1" {
  route_table_id         = aws_route_table.my.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my.id
}

# Public Subnet에 Public Route Table 연결
resource "aws_route_table_association" "my" {
  subnet_id      = aws_subnet.my.id
  route_table_id = aws_route_table.my.id
}

# Security Group for Public Subnet
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 인스턴스 (Public Subnet)
resource "aws_instance" "my" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  key_name   = "my-keypair-01"
  tags = {
    Name = "MY-EC2"
  }
}
