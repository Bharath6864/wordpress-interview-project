output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.web.dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.wordpress_db.endpoint
}

output "web_instance_public_ips" {
  description = "Public IP addresses of web instances"
  value       = aws_instance.web[*].public_ip
}