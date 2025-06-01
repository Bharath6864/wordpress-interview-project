output "ec2_insytance" {
  value = {
    public_ip  = aws_instance.test_run.public_ip
    private_ip = aws_instance.test_run.private_ip
  }

}