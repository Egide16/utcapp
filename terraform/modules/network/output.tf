output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "availability_zones" {
  value = local.azs
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  value = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  value = var.create_database_subnets ? aws_db_subnet_group.this[0].name : null
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "database_route_table_id" {
  value = var.create_database_subnets ? aws_route_table.database[0].id : null
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  value = aws_eip.nat[*].public_ip
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion.id
}

output "efs_security_group_id" {
  value = aws_security_group.efs.id
}