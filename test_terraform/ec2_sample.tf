provider "aws" {
    region = "eu-north-1"
}

data "aws_vpc" "default" {
    default = "true"
}

resource "aws_security_group" "allow_ssh_http" {
    name = "test_vpc"
    description = " Creating test ec2"
    vpc_id = data.aws_vpc.default.id

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
    vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
    tags = {
        name = "test"
    }
    associate_public_ip_address = true
}