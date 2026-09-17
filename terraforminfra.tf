# Configure AWS Provider
terraform{
    required_providers {
      aws= {
        source = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
}

# configure region
provider "aws"{
    region= "eu-central-1"
}

# VPC
resource "aws_vpc" "VPC-01"{
 cidr_block = "10.0.0.0/16"

 tags = {
   Name = "VPC-01"
 }
}

#Internet Gateway
resource "aws_internet_gateway" "VPC-01-IGW"{
    vpc_id = aws_vpc.VPC-01.id
    
    tags={
        Name="VPC-01-IGW"
    }
}

#Public Subnet
resource "aws_subnet" "VPC-01-PublicSN" {
    vpc_id = aws_vpc.VPC-01.id
    cidr_block = "10.0.1.0/24"

    tags={
        Name = "VPC-01-PublicSN"
    }

}

# Public Route Table
resource "aws_route_table" "VPC-01-PublicRT"{
    vpc_id= aws_vpc.VPC-01.id
    route{
    cidr_block="0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC-01-IGW.id
    }

    tags={
        Name ="VPC-01-PublicRT"
    }

}

# Association for Public Route Table
resource "aws_route_table_association" "VPC-01-PublicRT-Association"{
    subnet_id = aws_subnet.VPC-01-PublicSN.id
    route_table_id = aws_route_table.VPC-01-PublicRT.id
}

resource "aws_eip" "VPC-01-NAT-EIP"{
 domain= "vpc"
}

resource "aws_nat_gateway" "VPC-01-NAT-GW"{
 allocation_id= aws_eip.VPC-01-NAT-EIP.id
 subnet_id = aws_subnet.VPC-01-PublicSN.id
 
 }

resource "aws_subnet" "VPC-01-PrivateSN"{
    vpc_id = aws_vpc.VPC-01.id
    cidr_block = "10.0.2.0/24"

    tags={
        Name="VPC-01-PrivateSN"
    }
}

resource "aws_route_table" "VPC-01-PrivateRT"{
    vpc_id=aws_vpc.VPC-01.id

    route{
    cidr_block="0.0.0.0/0"
    gateway_id= aws_nat_gateway.VPC-01-NAT-GW.id
    }

tags = {
    Name = "VPC-01-PrivateRT"
  }
}

# Create association for Private route table named- VPC-01-Private-RT-Association
resource "aws_route_table_association" "VPC-01-Private-RT-Association" {
  subnet_id      = aws_subnet.VPC-01-PrivateSN.id
  route_table_id = aws_route_table.VPC-01-PrivateRT.id
}

#create security group
resource "aws_security_group" "VPC-01-NSG"{
    name="allow_tls"
    description = "Allow SSH Inbound and Outbound traffic"
    vpc_id= aws_vpc.VPC-01.id

    tags={
        Name="VPC-01-NSG"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4"{
    security_group_id =aws_security_group.VPC-01-NSG.id
    cidr_ipv4= "0.0.0.0/0"
    from_port= 22
    to_port=22
    ip_protocol="tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4"{
    security_group_id =aws_security_group.VPC-01-NSG.id
    cidr_ipv4= "0.0.0.0/0"    
    ip_protocol="-1"
}

#create public instance
resource "aws_instance" "Linux_WebServer"{
    ami="ami-081720d39920a9281"
    instance_type="t3.micro"
    key_name="Jenkins_Server_Key"
    subnet_id=aws_subnet.VPC-01-PublicSN.id
    vpc_security_group_ids = [aws_security_group.VPC-01-NSG.id]
    associate_public_ip_address = true

    tags={
        Name="Linux_WebServer"
    }
}


#create private instance
resource "aws_instance" "Linux_DBServer"{
    ami="ami-081720d39920a9281"
    instance_type="t3.micro"
    key_name="Jenkins_Server_Key"
    subnet_id=aws_subnet.VPC-01-PrivateSN.id
    vpc_security_group_ids = [aws_security_group.VPC-01-NSG.id]
    
    tags={
        Name="Linux_DBServer"
    }
}