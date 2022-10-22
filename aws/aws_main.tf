provider "aws" {
    region = "us-east-1"
    access_key = "my_access_key"
    secret_key = "my_secret_key"
  
}

# 1. create vpc
# on aws portal > services > ec2 > key pairs > create new > name > dl pem file > create key pair
# search for terraform vpc get the sample

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "production"
    }
  
}


# 2. create internet gateway
# terraform aws internet gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id
  
}
# 3. create custom route table
# terraform aws route table
resource "aws_route_table" "prod_route_table" {
    vpc_id = aws_vpc.prod-vpc.id
     route  {
       cidr_block = "0.0.0.0/0"
       gateway_id = aws_internet_gateway.gw.id

     }

     route {
         ipv6_cidr_block = "::/0"
         gateway_id = aws_internet_gateway.gw.id
     } 
     tags = {
       "Name" = "Prod"
     }
  
}

# define a variable
variable "subnet_prefix" {
    description = "cidr block for subnet"
    #default
    #type
  
}
# 4. create a subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet_prefix[0].cidr_block
    #cidr_block = "10.0.1.0/24"    
    availability_zone = "us-east-1a"

    tags = {
      #"Name" = "prod-subnet"
      "Name" = subnet_prefix[0].name

    }
  
}

resource "aws_subnet" "subnet-2" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block = var.subnet_prefix[1].cidr_block
    #cidr_block = "10.0.1.0/24"    
    availability_zone = "us-east-1a"

    tags = {
      #"Name" = "dev-subnet"
      "Name" = subnet_prefix[1].name
    }
  
}

# 5. associate subnet with route table
# terraform aws associate subnet
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod_route_table.id
  
}

# 6. create security group to allow port 22,80,443
# terraform aws security group
resource "aws_security_group" "allow_web" {
    name = "allow_web_traffic"
    description = "Allow web inbound traffic"
    vpc_id = aws_vpc.prod-vpc.id

    ingress {
        description = "HTTPS traffic"
        from_port = 443
        to_port = 443
        protocol = tcp
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTP traffic"
        from_port = 80
        to_port = 80
        protocol = tcp
        cidr_blocks = ["0.0.0.0/0"]
    }    
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = tcp
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_block = ["0.0.0.0/0"]
    } 

    tags = {
      "Name" = "allow-web"
    }
}
# 7. create a network interface with an IP in the subnet created in step 4
# terraform aws network interface
resource "aws_network_interface" "web-server-nic" {
    subnet_id = aws_subnet.subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_web.id]

  
}


# 8. assign an elastic IP to the network interface created in step 7
# terraform aws eip
resource "aws_eip" "one" {
    vpc = true
    network_interface = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.gw]
  
}

output "server_public_ip" {
    value = aws_eip.one.public_ip
  
}

# 9. create ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
    ami = "aws-ami"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "main-key"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id

    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }           
  
}

output "server_private_ip" {
    value = aws_instance.web-server-instance.private_ip

}

output "server_id" {
    value = aws_instance.web-server-instance.id
  
}
