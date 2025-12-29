variable "vpc_cidr" {}
variable "vpc_name" {}
variable "cidr_public_subnet" {}
variable "eu_availability_zone" {}
variable "cidr_private_subnet" {}

output "dev_proj_1_vpc_id" {
  value = aws_vpc.dev_proj_1_vpc_eu_central_1.id
}

output "dev_proj_1_public_subnets" {
  value = aws_subnet.dev_proj_1_public_subnets.*.id
}

output "public_subnet_cidr_block" {
  value = aws_subnet.dev_proj_1_public_subnets.*.cidr_block
}

# Setup VPC
resource "aws_vpc" "dev_proj_1_vpc_eu_central_1" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}


# Setup public subnet
resource "aws_subnet" "dev_proj_1_public_subnets" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "dev-proj-public-subnet-${count.index + 1}"
  }
}

#setting up the private subnet
# Setup private subnet

resource "aws_subnet" "dev_proj_1_private_subnets" {
  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "dev-proj-private-subnet-${count.index + 1}"
  }
}


# setup the internet gateway
resource "aws_internet_gateway" "dev_project_1_public_internet_gateway" {
  vpc_id = aws_vpc.dev_proj_1_vpc_eu_central_1.id

  tags = {
    Name = "dev-project-1-igw"
  }
}


#setup the route table for the public subnet
resource "aws_route_table" "dev_proj_1_public_route_table"{
  vpc_id = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_project_1_public_internet_gateway.id
  }

  tags = {
    Name = "dev-proj-1-public-rt"
  }
}



# #public route table association with public subnet
# resource "aws_route_table_association" "dev_proj_1_public_route_table_association" {
#   count = length(aws.subnet.dev_proj_1_public_subnets)
#   subnet_id = aws.subnet.dev_proj_1_public_subnets[count.index].id
#   route_table_id = aws_route_table.dev_proj_1_public_route_table.id
# }



#Route table for the private subnet
resource "aws_route_table" "dev_proj_1_private_route_table"{
  vpc_id = aws_vpc.dev_proj_1_vpc_eu_central_1.id
  tags = {
    Name = "dev-proj-1-private-rt"
  }
}


# #Route table association with private subnet

# resource "aws_route_table_association" "dev_proj_1_private_route_table_association" {
#   count = length(aws.subnet.dev_proj_1_private_subnets)
#   subnet_id = aws.subnet.dev_proj_1_private_subnets[count.index].id
#   route_table_id = aws_route_table.dev_proj_1_private_route_table.id
# }