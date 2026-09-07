variable "region" {
  type    = string
  default = "us-east-1"
}

variable "primary_vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "secondary_vpc_cidr" {
  default = "10.2.0.0/16"
}

variable "primary_subnet_cidr" {
  description = "CIDR block for primary subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "secondary_subnet_cidr" {
  description = "CIDR block for secondary subnet"
  type        = string
  default     = "10.2.0.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
