resource "aws_vpc" "app_vpc" {
  cidr_block = "192.168.0.0/16"
  assign_generated_ipv6_cidr_block = false
  enable_dns_support = true
  tags = {
    Name = "WP Solution VPC"
  }
}

#create igw
resource "aws_internet_gateway" "app_igw" {
  vpc_id = "${aws_vpc.app_vpc.id}"
}



# Pull data for AZs in region
data "aws_availability_zones" "available" {}

#provision public subnet 1
resource "aws_subnet" "pub_subnet1"{
  # Ensures subnet is created in it's own AZ
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  vpc_id = "${aws_vpc.app_vpc.id}"
  cidr_block = "192.168.10.0/24"
  tags = {
      Name = "public subnet 1"
  }
}

#public subnet 2
resource "aws_subnet" "pub_subnet2"{
  # Ensures subnet is created in it's own AZ
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  vpc_id = "${aws_vpc.app_vpc.id}"
  cidr_block = "192.168.11.0/24"
  tags = {
      Name = "public subnet 2"
  }
}

#provision webserver subnet
resource "aws_subnet" "web_subnet1" {
  vpc_id = "${aws_vpc.app_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block = "192.168.20.0/24"
  tags = {
    Name = "web server subnet 1"
  }
}


#provision database subnet #1
resource "aws_subnet" "db_subnet1" {
  vpc_id = "${aws_vpc.app_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block = "192.168.30.0/24"
  tags = {
    Name = "database subnet 1"
  }
}

#provision database subnet #2
resource "aws_subnet" "db_subnet2" {
  vpc_id = "${aws_vpc.app_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block = "192.168.31.0/24"
  tags = {
    Name = "database subnet 2"
  }
}

#new default route table 
resource "aws_default_route_table" "default" {
   default_route_table_id = "${aws_vpc.app_vpc.default_route_table_id}"

   route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_internet_gateway.app_igw.id}"
   }
}

# provision EIP for nat gateway 1
resource "aws_eip" "gwip1" {
}



# NAT Gateway for Web subnet 1 (to pull packages, docker, etc)
resource "aws_nat_gateway" "gw1" {
  allocation_id = "${aws_eip.gwip1.id}"
  subnet_id = "${aws_subnet.pub_subnet1.id}"
  tags = {
    Name = "Wordpress TF NAT Gateway 1"
  }
}



