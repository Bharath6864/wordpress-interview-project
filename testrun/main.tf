resource "aws_instance" "test_run" {
  ami                         = "ami-02ec57994fa0fae21"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.test_run.id]
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.testkey.id
  associate_public_ip_address = true
  availability_zone           = "eu-north-1a"

  tags = {
    name = "test"
  }

}

resource "aws_security_group" "test_run" {
  name        = "test_run"
  description = "Security group for test run instance"
  vpc_id      = aws_vpc.test_vpc.id

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
    enable_dns_support          = true
    enable_dns_hostnames        = true

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

resource "aws_key_pair" "testkey" {
  key_name   = "test-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmJctPaFHtQw7UNPdVvsHUoUDFnP4Rivod0qLbNpuGbwvX/MY/gt7/5uAlsac9Tw7OFYhpx7yeWWaSeb2du3tL5XDP6/dbTuBciNi56UTQyn/cKvsXu9ItqIYq6zH7+cI/UG9BerSjUQ+O9Cqf0lhW9S/D+oBv70HUZHgGBvoAvJy2C6YpxicJuzDG2Flf+L6WRN3ZQg6k0k2U59Y5HvJg8oh53JGQ1uHtHf9yO4O3pDN4xul29W4cMM5QYUCtxGlUxBHRQWOW+KkDDDZFyNnlTN21MNaNFSADItP+dEZQmvYeKOC/SLkHxvH5WNe3LrKoW4Jc8fYEdP0eTgtV8RcC3EKWGwarIHW8mZT8pc9lZW9NE2RuqjxZhuaI6gKMLBr3aTH7i6bfh9gHTr3u6MLkpZGuTof/dQEPFWlqAnvr3q8Eohni1Qy/vvK1Om8JY+w3FlqIXlFZgo37AEBGvznG9CfHLXVdB1m5PhBmKM5VF6EaCE7gtRtZLB/c+kEWhKTh1vj1nruJLZpptggiIC5cbtRZdjjxxNzFkb+bJ1ogvW462tw9urlg3wdKLpvWStppN3VXHqz11GImSSBaOswdNePr/wXNpPWSYiix2lkbft/Nng89f1IAbT2jXbJBd0YJP/oke27sH9MWrI9CYJIHWZOFrpUQPiTn5uwnwnTvFQ== Bharath M@DESKTOP-M1TN014"

  tags = {
    name = "test"
  }
}

resource "aws_eip" "testeip" {
  instance = aws_instance.test_run.id
  vpc      = true
}

#network address translation gateway

resource "aws_nat_gateway" "test_nat" {
  allocation_id = aws_eip.testeip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "test"
  }
}

resource "aws_route_table" "test_route" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.test_nat.id
  }
  tags {
    name = "test"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.test_route.id

  tags{
    name = "test"
  }
}