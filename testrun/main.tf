resource "aws_instance" "test_run" {
  ami                         = "ami-02ec57994fa0fae21"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.test_run.id]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  availability_zone           = "eu-north-1a"

  tags = {
    name = "test"
  }

}

resource "aws_security_group" "test_run" {
  name        = "test_run"
  description = "Security group for test run instance"
  vpc_id = aws_vpc.test_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    name = "test_run_sg"
  }

}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test_vpc"
  }

}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "test"
  }

}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    name = "test"
  }

}

resource "aws_network_acl" "test_acl" {
  vpc_id     = aws_vpc.test_vpc.id
  subnet_ids = [aws_subnet.public.id]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    rule_no    = 200
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  ingress {
    rule_no    = 300
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

}


resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags = {
    Name = "test"
  }

}

resource "aws_route_table" "test_route_table" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test"
  }

}

resource "aws_route" "test_route" {
  route_table_id         = aws_route_table.test_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.test_igw.id
}

resource "aws_route_table_association" "test_table_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.test_route_table.id
}
