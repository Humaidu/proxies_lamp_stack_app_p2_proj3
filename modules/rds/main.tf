
resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "lamp-db-credentials-${random_id.secret_suffix.hex}"
}

resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "lamp_admin"
    password = random_password.db_password.result
    dbname   = var.db_name
  })
}

resource "aws_db_subnet_group" "lamp_db_subnet" {
  name       = "lamp-db-subnet-group"
  subnet_ids = var.private_subnets
}

resource "aws_security_group" "rds_sg" {
  name        = "lamp-rds-sg"
  description = "Allow MySQL access from web servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For demo only - restrict to web SG in production
  }

  tags = {
    Name = "lamp-rds-sg"
  }
}

resource "aws_db_instance" "lamp_db" {
  identifier             = "lamp-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_subnet_group_name   = aws_db_subnet_group.lamp_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  username               = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)["username"]
  password               = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)["password"]
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  
}
