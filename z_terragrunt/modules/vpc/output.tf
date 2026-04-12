output "vpc_id" {
  value = aws_vpc.mainvpc.id
}

# CHANGE: added useful outputs
output "public_subnet_id" {
  value = aws_subnet.pubsn1.id
}

output "private_subnet_id" {
  value = aws_subnet.pvtsn1.id
}