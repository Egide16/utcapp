output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "efs_file_system_id" {
  value = var.enable_efs ? aws_efs_file_system.this[0].id : null
}

output "efs_access_point_id" {
  value = var.enable_efs ? aws_efs_access_point.app[0].id : null
}