provider "aws" {
    region = "eu-north-1"
}

resource "aws_vpc" "vpc_test" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags = {
        name = "tets"
    }
}

resource "aws_subnet" "subnet_test" {
    vpc_id = aws_vpc.vpc_test.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-north-1a"
    map_public_ip_on_launch = true
    tags = {
        name = "test"
    }

}

resource "aws_security_group" "allow_ssh_http" {
    name = "test_vpc"
    description = "Creating test ec2"
    vpc_id = aws_vpc.vpc_test.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        name = "test"
    }
}

resource "aws_instance" "free_tier_ec2" {
    ami = 	"ami-00f34bf9aeacdf007"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.subnet_test.id
    vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
    tags = {
        name = "test"
    }
    associate_public_ip_address = true
}