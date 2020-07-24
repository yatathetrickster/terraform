# Configuring AWS as the provider
provider "aws" {
    region = "us-east-1"
    access_key = "put-access-key-id-here"
    secret_key = "put-secret-key-here"
}

# Creating a VPC
resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "prod-vpc"
    }
}

# Creating an Internet Gateway
resource "aws_internet_gateway" "prod-ig" {
    vpc_id = aws_vpc.prod-vpc.id

    tags = {
        Name = "prod-internet-gateway"
    }
}

# Creating a Route Table
resource "aws_route_table" "prod-rt" {
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.prod-ig.id
    }

    tags = {
        Name = "prod-route-table"
    }
}

# Creating a Subnet
resource "aws_subnet" "prod-subnet" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "prod-subnet"
    }
}

# Associate Route Table to Subnet
resource "aws_route_table_association" "prod-rsa" {
    subnet_id = aws_subnet.prod-subnet.id
    route_table_id = aws_route_table.prod-rt.id
}

# Creating a Security Group to Allow Ports 22 and 80
resource "aws_security_group" "prod-sg" {
    name = "allow-traffic"
    description = "allow ssh and web traffic"
    vpc_id = aws_vpc.prod-vpc.id

    ingress {
        description = "allow inbound traffic on port 22"
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "allow inbound traffic on port 80"
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "prod-security-group"
    }
}

# Creating a Network Interface with an IP Address from the Subnet
resource "aws_network_interface" "prod-vm-nic" {
    subnet_id = aws_subnet.prod-subnet.id
    private_ips = ["10.0.1.10"]
    security_groups = [aws_security_group.prod-sg.id]

    tags = {
        Name = "prod-nic-private-ip"
    }
}

# Assigning an Elastic IP to the Network Interface
resource "aws_eip" "prod-vm-nic-eip" {
    vpc = "true"
    network_interface = aws_network_interface.prod-vm-nic.id
    associate_with_private_ip = "10.0.1.10"
    depends_on = [aws_internet_gateway.prod-ig]

    tags = {
        Name = "prod-elastic-ip"
    }
}

# Creating an Ubuntu vm and Configuring Apache
resource "aws_instance" "prod-instance" {
    ami = "ami-0ac80f6eff0e70b5"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "prod-key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.prod-vm-nic.id
        }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo bash -c 'echo this vm is provisioned using terraform > /var/www/html/index.html'
                EOF
    tags = {
        Name = "prod-web-server"
    }
}