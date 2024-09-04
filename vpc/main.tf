# vpc 정의
resource "aws_vpc" "this" {
  cidr_block = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_network_address_usage_metrics = true
  tags = {
    Name = "obs-eks-vpc"
  }
}

# IGW를 생성
resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id
    tags = {
      Name = "obs-eks-vpc-igw" 
    }
} 

# NATGW를 위한 탄력 IP 생성
resource "aws_eip" "this" {
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "obs-eks-vpc-eip"
  }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "pub_sub1" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.10.1.0/24"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "obs-eks-vpc-pub-sub1"
    "kubernetes.io/role/elb" = 1
  }
  depends_on = [ aws_internet_gateway.this ]
}
resource "aws_subnet" "pub_sub2" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.10.2.0/24"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "obs-eks-vpc-pub-sub2"
    "kubernetes.io/role/elb" = 1
  }
  depends_on = [ aws_internet_gateway.this ]
}

# 프라이빗 서브넷 생성
resource "aws_subnet" "pri_sub1" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.10.11.0/24"
  enable_resource_name_dns_a_record_on_launch = true
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "obs-eks-vpc-pri-sub1"
    "kubernetes.io/role/internal-elb" = 1
  }
  depends_on = [ aws_nat_gateway.this ]
}
resource "aws_subnet" "pri_sub2" {
  vpc_id = aws_vpc.this.id
  cidr_block = "10.10.12.0/24"
  enable_resource_name_dns_a_record_on_launch = true
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "obs-eks-vpc-pri-sub2"
    "kubernetes.io/role/internal-elb" = 1
  }
  depends_on = [ aws_nat_gateway.this ]
}

# NATGW 생성
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id = aws_subnet.pub_sub1.id
  tags = {
    Name = "obs-eks-vpc-ngw"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# 퍼블릭 라우팅 테이블 정의
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "10.10.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "obs-eks-vpc-pub-rt"
  }
}

# 프라이빗 라우팅 테이블 정의
resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "10.10.0.0/16"
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "obs-eks-vpc-pri-rt"
  }
}

# 퍼블릭 라우팅 테이블과 서브넷을 연결
resource "aws_route_table_association" "pub1_rt_asso" {
  subnet_id = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "pub2_rt_asso" {
  subnet_id = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.pub_rt.id
}

# 프라이빗 라우팅 테이블과 서브넷을 연결
resource "aws_route_table_association" "pri1_rt_asso" {
  subnet_id = aws_subnet.pri_sub1.id
  route_table_id = aws_route_table.pri_rt.id
}
resource "aws_route_table_association" "pri2_rt_asso" {
  subnet_id = aws_subnet.pri_sub2.id
  route_table_id = aws_route_table.pri_rt.id
}

# 보안그룹 생성
resource "aws_security_group" "eks-vpc-pub-sg" {
  name        = "obs-eks-vpc-pub-sg"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "obs-eks-vpc-pub-sg"
  }
}

# 인그리스 규칙
resource "aws_security_group_rule" "eks-vpc-ssh-ingress" {
  security_group_id = aws_security_group.eks-vpc-pub-sg.id

  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  lifecycle {
    create_before_destroy = true
  }
}

#이그리스 규칙
resource "aws_security_group_rule" "eks-vpc-ssh-egress" {
  security_group_id = aws_security_group.eks-vpc-pub-sg.id

  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  lifecycle {
    create_before_destroy = true
  }
}