#VPC
resource "aws_vpc" "Primary_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "Primary-VPC"
    Environment = "production-primary"
  }
}

#Primary Subnets Public 
resource "aws_subnet" "Primary_sub_pub" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "Primary-Public-Subnet-1"
    Environment = "production-primary"
  }
}
resource "aws_subnet" "Primary_sub_pub_2" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name        = "Primary-Public-Subnet-2"
    Environment = "production-primary"
  }
}
#Primary Subnets Private
resource "aws_subnet" "Primary_sub_priv" {
  vpc_id = aws_vpc.Primary_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name        = "Primary-Private-Subnet"
    Environment = "production-primary"
  }
}

resource "aws_subnet" "Primary_sub_priv2" {
  vpc_id = aws_vpc.Primary_vpc.id
  availability_zone = "eu-west-2b"
  cidr_block = "10.0.3.0/24"
  tags = {
    Name        = "Primary-Private-Subnet2"
    Environment = "production-primary"
  }
}

#Internet Gateway for Primary VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-IGW"
    Environment = "production-primary"
  }
}
#routetable for Primary VPC
resource "aws_route_table" "RT_prim" {
  vpc_id = aws_vpc.Primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name        = "Primary-Public-RT"
    Environment = "production-primary"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.Primary_sub_pub.id
  route_table_id = aws_route_table.RT_prim.id
}


resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.Primary_sub_pub_2.id
  route_table_id = aws_route_table.RT_prim.id
}


resource "aws_route_table" "RT_Prim_Priv" {
  vpc_id = aws_vpc.Primary_vpc.id
  tags = {
    Name        = "Primary-Private-RT"
    Environment = "production-primary"
  }
}  


resource "aws_route_table_association" "rtap1" {
  subnet_id      = aws_subnet.Primary_sub_priv.id
  route_table_id = aws_route_table.RT_Prim_Priv.id
}

resource "aws_route_table_association" "rtap2" {
  subnet_id      = aws_subnet.Primary_sub_priv2.id
  route_table_id = aws_route_table.RT_Prim_Priv.id
}


#Nat Gateway Setup for ECS Task to run whilst being isolated in private subnet

resource "aws_eip" "nat_eip" {
  domain = "vpc"  # Ensure the EIP is allocated for use in a VPC
  tags = {
    Name        = "Primary-NAT-EIP"
    Environment = "production-primary"
  }
}


# NAT Gateway in Public Subnet
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.Primary_sub_pub.id  # Attach NAT GW to public subnet

  tags = {
    Name        = "Primary-NAT-Gateway"
    Environment = "production-primary"
  }
}

# Route for Private Subnets to use NAT Gateway for internet access
resource "aws_route" "nat_route" {
  route_table_id         = aws_route_table.RT_Prim_Priv.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}
