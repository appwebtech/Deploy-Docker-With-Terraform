provider "aws" {
  region     = "eu-west-1"
}

variable "cidr_blocks" {
  description = "cidr block for vpc and subnets"
  type        = list(string)
}

variable avail_zone {}

variable "availability_zone" {
	type = list(string)
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr_blocks[0]
  tags = {
    Name : "development"
    vpc_env : "dev"
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id            = aws_vpc.development-vpc.id
  cidr_block        = var.cidr_blocks[1]
  availability_zone = var.availability_zone[0]
  tags = {
    Name : "subnet-1-dev"
  }
}

output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
  value = aws_subnet.dev-subnet-1.id
}
