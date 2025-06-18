# ──────── Retrieve DB Credentials from AWS Secrets Manager ────────

# Get the secret metadata using its ARN
data "aws_secretsmanager_secret" "db_secret" {
  arn = var.db_secret_arn
}

# Get the current version of the secret containing actual credentials
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

# Decode the secret string into a local variable for usage
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

# ──────── Security Group for Web Server ────────

resource "aws_security_group" "web_sg" {
  name        = "lamp-web-sg"
  description = "Allow HTTP/HTTPS and SSH traffic"
  vpc_id      = var.vpc_id

  # Allow incoming HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (not safe for production - restrict in real setups)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ──────── Launch Template for EC2 Instances ────────

resource "aws_launch_template" "lamp_lt" {
  name_prefix   = "lamp-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  # Network settings: assign public IP and attach SG
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  # user-data script for PHP + CloudWatch agent installation

  user_data = base64encode(templatefile("${path.root}/user_data.sh", {
    db_endpoint  = var.db_endpoint,
    db_name      = local.db_credentials.dbname,
    db_username  = local.db_credentials.username,
    db_password  = local.db_credentials.password,  
    project_name = var.project_name
  }))


  # Attach IAM role for EC2 with permissions for CloudWatch and S3
  iam_instance_profile {
    name = var.instance_profile_name
  }

  # Tag EC2 instances
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "LAMP-WebServer"
    }
  }
}

# ──────── S3 Bucket and PHP App Upload ────────

# Create S3 bucket to store PHP app files
resource "aws_s3_bucket" "my_php_bucket" {
  bucket        = "lamp-stack-app-bucket-0921"
  force_destroy = true # helpful for testing, removes bucket on destroy
}

# Upload PHP files from local php-app/ to S3
resource "aws_s3_object" "php_app" {
  for_each = fileset("${path.root}/php-app/", "**/*")
  bucket   = aws_s3_bucket.my_php_bucket.bucket
  key      = "php-app/${each.value}"
  source   = "${path.root}/php-app/${each.value}"
  etag     = filemd5("${path.root}/php-app/${each.value}")
}

# ──────── Auto Scaling Group with ALB Integration ────────

resource "aws_autoscaling_group" "lamp_asg" {
  name_prefix         = "lamp-asg-"
  vpc_zone_identifier = var.public_subnets
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2

  # Link to launch template
  launch_template {
    id      = aws_launch_template.lamp_lt.id
    version = "$Latest"
  }

  # Ensure files are uploaded before creating instances
  depends_on = [aws_s3_object.php_app]

  # Link to ALB target group for traffic distribution
  target_group_arns = [aws_lb_target_group.lamp_tg.arn]
  health_check_type = "ELB"
}

# ──────── Application Load Balancer (ALB) ────────

# Define the ALB that will distribute traffic across instances
resource "aws_lb" "lamp_alb" {
  name               = "lamp-alb"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = var.public_subnets
}

# Define target group for ALB to direct traffic to web instances
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

# Forward incoming HTTP requests on port 80 to the target group
resource "aws_lb_listener" "lamp_listener" {
  load_balancer_arn = aws_lb.lamp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lamp_tg.arn
  }
}

# ──────── Fetch Amazon Linux AMI ────────

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ──────── IAM Role and Policies ────────

# IAM role to allow EC2 to use AWS services like CloudWatch and S3
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

# Attach inline policy to EC2 role for reading S3 bucket contents
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

# Create IAM Instance Profile for EC2 to attach the above role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lamp-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
