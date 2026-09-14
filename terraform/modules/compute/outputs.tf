output "launch_template_id" {
  value = aws_launch_template.app.id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  value = aws_autoscaling_group.app.arn
}

output "app_iam_role_arn" {
  value = aws_iam_role.app_instance.arn
}

output "scaling_sns_topic_arn" {
  value = aws_sns_topic.scaling.arn
}

output "bastion_instance_id" {
  value = var.enable_bastion ? aws_instance.bastion[0].id : null
}

output "bastion_public_ip" {
  value = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}
output "bastion_iam_role_arn" {
  value = var.enable_bastion ? aws_iam_role.bastion[0].arn : null
}