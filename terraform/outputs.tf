output "ec2_instance_1_private_ip" {
  description = "Private IP address of the EC2 instance in VPC 1"
  value       = aws_instance.primary_instance.private_ip
}

output "ec2_instance_2_private_ip" {
  description = "Private IP address of the EC2 instance in VPC 2"
  value       = aws_instance.secondary_instance.private_ip
}

# output "ec2_instance_1_public_ip" {
#   description = "Public IP address of the EC2 instance in VPC 1"
#   value       = aws_instance.primary_instance.public_ip
# }

# output "ec2_instance_2_public_ip" {
#   description = "Public IP address of the EC2 instance in VPC 2"
#   value       = aws_instance.secondary_instance.public_ip
# }