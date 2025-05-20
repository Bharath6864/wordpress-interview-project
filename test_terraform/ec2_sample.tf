provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "ec2_instance" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t2.micro"

    tag = {
        name = "test"
    }
    associate_public_ip_address = true
}