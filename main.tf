provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "WordPress-VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "WordPress-IGW"
  }
}

# Create Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-${count.index + 1}"
  }
}

# Create Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "Private-Subnet-${count.index + 1}"
  }
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public-Route-Table"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create Security Group for EC2 instances
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-Security-Group"
  }
}

# Create Security Group for RDS
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL traffic from web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-Security-Group"
  }
}

# Create RDS MySQL Instance
resource "aws_db_instance" "wordpress_db" {
  allocated_storage      = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  name                  = "wordpressdb"
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = "default.mysql5.7"
  db_subnet_group_name  = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot   = true
  publicly_accessible   = false
  storage_encrypted     = true
}

# Create DB Subnet Group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "wordpress-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = {
    Name = "WordPress-DB-Subnet-Group"
  }
}

# Create Launch Configuration for Auto Scaling
resource "aws_launch_configuration" "web" {
  name_prefix     = "wordpress-web-"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_sg.id]
  key_name        = aws_key_pair.deployer.key_name
  user_data       = <<-EOF
                  #!/bin/bash
                  apt-get update
                  apt-get install -y apache2 php php-mysql
                  wget https://wordpress.org/latest.tar.gz
                  tar -xzf latest.tar.gz -C /var/www/html/
                  chown -R www-data:www-data /var/www/html/wordpress
                  chmod -R 755 /var/www/html/wordpress
                  systemctl restart apache2
                  EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                 = "wordpress-asg"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = aws_subnet.public[*].id
  target_group_arns    = [aws_lb_target_group.web.arn]

  tag {
    key                 = "Name"
    value               = "WordPress-Web-Server"
    propagate_at_launch = true
  }
}

# Create Application Load Balancer
resource "aws_lb" "web" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Create Target Group
resource "aws_lb_target_group" "web" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Create Load Balancer Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}