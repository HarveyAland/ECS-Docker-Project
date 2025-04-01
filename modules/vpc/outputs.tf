output "vpc_id" {
  value = aws_vpc.Primary_vpc.id
}

output "Pubsub1" {
  value = aws_subnet.Primary_sub_pub.id
}

output "Pubsub2" {
  value = aws_subnet.Primary_sub_pub_2.id
}

output "Privsub1" {
  value = aws_subnet.Primary_sub_priv.id
}

output "Privsub2" {
  value = aws_subnet.Primary_sub_priv2.id
}