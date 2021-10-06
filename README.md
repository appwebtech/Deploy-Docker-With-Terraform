# Docker Container with Terraform


<p float="left">
  <img src="https://github.com/appwebtech/Deploy-Docker-With-Terraform/blob/main/images/docker.png" width="100">

  <img src="https://github.com/appwebtech/EKS-Cluster-With-Terraform/blob/main/images/tf-logo.png" width="100">
</p>

----
## Introduction

I will be provisioning an EC2 instance on AWS infrastructure, subsequent to which I will run a Docker container in the EC2 instance and deploy an nginx server using Terraform. Just a simple infrastructure with only a VPC and a subnet to simulate a simple web application deployment with a webserver.

Stack preparation:
1. VPC
2. 1 Subnet
3. Route Table & Internet Gateway
   * To allow internet connectivity
4. Provision EC2 instance
5. Deploy **nginx** Docker container
6. Create **Security Group** (Firewall)

## VPC and Subnet

Creation of the VPC and subnet.

```terraform
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id     = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}
```

## Internet Gateway and Route Table

An **internet gateway** is a horizontally scaled, redundant, and highly available VPC component that allows communication between your VPC and the internet.

An internet gateway serves two purposes: 

1. Provision of a target in the VPC route table for internet-routable traffic.
2. To perform network address translation (NAT) for instances that have been assigned public IPv4 addresses. Ipv6 addresses are now supported.

A **route table** contains a set of rules, called routes, that are used to determine where network traffic from your subnet or gateway is directed. 

```terraform
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name : "${var.env_prefix}-rtb"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name : "${var.env_prefix}-igw"
  }
} 

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}
```

![igw-rtb](./images/image-1.png)

## Security Group

A security group acts as a virtual firewall for your EC2 instances to control incoming and outgoing traffic. Inbound rules control the incoming traffic to your instance, and outbound rules control the outgoing traffic from your instance. 

Instead of opening port 22 to the world, I have limited it to my home IP and saved it as an environment variable in my **.tfvars** file which I won't commit and push to a public repository.

```terraform
resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port  = 22
    to_port    = 22
    protocol   = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port  = 8080
    to_port    = 8080
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name : "${var.env_prefix}-sg"
  }
}
```

![sg](./images/image-2.png)

## EC2 Instance

I have created the EC2 instance by pullling the image **ami** from AWS insted of hard coding in the text editor. This is because AWS and the AWS market place developers keep updating ami's which in turn change the ID's.

```terraform
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  key_name                    = "fedora"

  tags = {
    Name : "${var.env_prefix}-server"
  }
}
```

![ec2](./images/image-3.png)

I will SSH inside the instance because I have it initialized.

![ssh](./images/image-4.png)

## Docker and Nginx Deployment

I will be automating the installation process of Docker and Nginx by using a script file, which I have saved as **user-data.sh**. Normally whilst instantiating EC2 instances, the AWS UI grants you the option of using pasting a script in the UI to avoid SSH'ing and running the commands manually online.

In my case I'll create a script file and bind it to the EC2 instance resource code block and execute terraform apply. The script will use the yum package manager to run updates (I'm using Amazon centOS rhel fedora), install docker, start docker, create a group for ec2-user, then run and bind docker on port 8080 from port 80 of the container.

User data script;

```shell
#!/bin/bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx
```

![ssh](./images/image-5.png)

</hr>

![ssh](./images/image-6.png)

</hr>

![ssh](./images/image-7.png)

There it is. A simple but very realistic configuration of creating an environment with Terraform and deploying a websever using Docker container.

