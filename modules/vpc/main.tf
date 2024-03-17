provider "aws" {
  region = var.region
}

resource "aws_vpc" "totem-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = var.tags
}

data "aws_availability_zones" "available" {
  
}

resource "aws_subnet" "subnets" {
  count = 2
  vpc_id = aws_vpc.totem-vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  tags = var.tags
}

resource "aws_internet_gateway" "totem-igtw" {
  vpc_id = aws_vpc.totem-vpc.id
  tags = var.tags
}

resource "aws_route_table" "totem-rtb" {
  vpc_id = aws_vpc.totem-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.totem-igtw.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "new-rtb-association" {
  count = 2
  route_table_id = aws_route_table.totem-rtb.id
  subnet_id = aws_subnet.subnets.*.id[count.index]
}