provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "free_tier_ec2" {
    ami = 	"ami-00f34bf9aeacdf007"
    instance_type = "t3.micro"

    tags = {
        name = "test"
    }
    associate_public_ip_address = true
}