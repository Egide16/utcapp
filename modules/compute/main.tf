locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  efs_mount_script = var.efs_file_system_id != "" ? join("\n", [
    "dnf install -y amazon-efs-utils",
    "mkdir -p ${var.mount_path}",
    "mount -t efs -o tls,accesspoint=${var.efs_access_point_id} ${var.efs_file_system_id}:/ ${var.mount_path}",
    "echo \"${var.efs_file_system_id}:/ ${var.mount_path} efs _netdev,tls,accesspoint=${var.efs_access_point_id} 0 0\" >> /etc/fstab"
  ]) : ""

  default_user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    echo "<h1>${local.name_prefix} app server - $(hostname -f)</h1>" > /var/www/html/index.html
    systemctl start httpd
    ${local.efs_mount_script}
  EOF
}

resource "aws_iam_role" "app_instance" {
  name = "${local.name_prefix}-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_instance" {
  name = "${local.name_prefix}-app-instance-profile"
  role = aws_iam_role.app_instance.name
}

resource "aws_iam_role_policy" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  name = "${local.name_prefix}-s3-access"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.s3_bucket_arn
      },
      {
        Sid      = "ReadWriteObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "efs_access" {
  count = var.enable_efs_access ? 1 : 0

  name = "${local.name_prefix}-efs-access"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EfsMount"
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeMountTargets"
        ]
        Resource = "arn:aws:elasticfilesystem:*:*:file-system/${var.efs_file_system_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy" "secrets_access" {
  count = var.enable_secrets_access ? 1 : 0

  name = "${local.name_prefix}-secrets-access"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetDbSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      }
    ]
  })
}
# ---------------------------------------------------------------------------
# IAM role for bastion — adds SSM Session Manager as a second access path
# ---------------------------------------------------------------------------

resource "aws_iam_role" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name = "${local.name_prefix}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  count = var.enable_bastion ? 1 : 0

  role       = aws_iam_role.bastion[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name = "${local.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion[0].name
}
resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-app-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.app_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance.name
  }

  vpc_security_group_ids = [var.app_security_group_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(coalesce(var.app_user_data, local.default_user_data))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-app-volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.target_group_arns

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${local.name_prefix}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = var.scale_out_cooldown
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${local.name_prefix}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = var.scale_in_cooldown
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Scale out when average CPU exceeds ${var.cpu_high_threshold}%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_out.arn,
    aws_sns_topic.scaling.arn
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${local.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "Scale in when average CPU drops below ${var.cpu_low_threshold}%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_in.arn,
    aws_sns_topic.scaling.arn
  ]

  tags = local.common_tags
}

resource "aws_sns_topic" "scaling" {
  name = "${local.name_prefix}-auto-scaling"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "scaling_email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.scaling.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_autoscaling_notification" "this" {
  group_names = [aws_autoscaling_group.app.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.scaling.arn
}

resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion[0].name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion"
  })
}