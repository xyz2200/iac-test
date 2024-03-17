output "vpc_id" {
  value = aws_vpc.totem-vpc.id
}

output "subnet_ids" {
  value = aws_subnet.subnets[*].id
}