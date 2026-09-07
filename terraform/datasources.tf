data "aws_availability_zones" "primary" {
  state = "available"
}

data "aws_availability_zones" "secondary" {
  state = "available"
}

data "aws_ami" "primary_ami" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.12.*-kernel-6.18-x86_64"]
  }
}

data "aws_ami" "secondary_ami" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.12.*-kernel-6.18-x86_64"]
  }
}