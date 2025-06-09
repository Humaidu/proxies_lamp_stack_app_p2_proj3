data "aws_secretsmanager_secret" "db_secret" {
  arn = var.db_secret_arn
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

resource "aws_security_group" "web_sg" {
  name        = "lamp-web-sg"
  description = "Allow HTTP/HTTPS and SSH traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "lamp_lt" {
  name_prefix   = "lamp-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(templatefile("${path.root}/user_data.sh", {
    db_endpoint = var.db_endpoint
    db_name     = local.db_credentials.dbname
    db_username = local.db_credentials.username
    db_password = local.db_credentials.password
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "LAMP-WebServer"
    }
  }
}

# Create an s3 bucket
resource "aws_s3_bucket" "my_php_bucket" {
  bucket = "lamp-stack-app-bucket-0921"
  force_destroy = true # helps clean up during testing
}

# Upload PHP files to S3 (alternative to direct copy)
resource "aws_s3_object" "php_app" {
  for_each = fileset("${path.root}/php-app/", "**/*")
  bucket   = aws_s3_bucket.my_php_bucket.bucket
  key      = "php-app/${each.value}"
  source   = "${path.root}/php-app/${each.value}"
  etag     = filemd5("${path.root}/php-app/${each.value}")
}

resource "aws_autoscaling_group" "lamp_asg" {
  name_prefix          = "lamp-asg-"
  vpc_zone_identifier = var.public_subnets
  desired_capacity    = 2
  max_size           = 3
  min_size           = 2

  launch_template {
    id      = aws_launch_template.lamp_lt.id
    version = "$Latest"
  }

  depends_on = [aws_s3_object.php_app]

  target_group_arns = [aws_lb_target_group.lamp_tg.arn]
  health_check_type = "ELB"
}

resource "aws_lb" "lamp_alb" {
  name               = "lamp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "lamp_tg" {
  name     = "lamp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "lamp_listener" {
  load_balancer_arn = aws_lb.lamp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lamp_tg.arn
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "lamp-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "s3_read" {
  name = "lamp-ec2-s3-policy"
  role = aws_iam_role.ec2_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Resource = [
        "arn:aws:s3:::lamp-stack-app-bucket-0921",
        "arn:aws:s3:::lamp-stack-app-bucket-0921/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lamp-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
