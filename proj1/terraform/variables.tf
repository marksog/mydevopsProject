variable "aws_region" {
    description = "AWS region to deploy resources"
    type       = string
}

variable "vpc_cidr" {
    description = "CIDR block for VPC"
    type = string
}

variable "instance_tenancy" {
    description = "Instance tenancy for VPC"
    type = string
    default = "dev"
}

variable "tag_overlay" {
    description = "Tags to be applied to resources"
    type = map(string)
    default = {
        Name = "terraform-vpc"
        Env = "Sandbox"
        ProjectID = "MK001"
        PM = "mm"
    }  
}

variable "public_subnet_a_cidr" {
    description = "CIDR block for public subnet"
    type = string
  
}

variable "public_subnet_b_cidr" {
    description = "CIDR block for public subnet"
    type = string
  
}

variable "private_subnet_a_cidr" {
    description = "CIDR block for public subnet"
    type = string
  
}

variable "private_subnet_b_cidr" {
    description = "CIDR block for public subnet"
    type = string
  
}

variable "pubrt_cidrblock" {
    description = "CIDR block for public route table"
    type = string
  
}

variable "privrt_cidrblock" {
    description = "CIDR block for private route table"
    type = string
  
}

