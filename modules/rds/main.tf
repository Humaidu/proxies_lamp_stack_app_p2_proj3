# Generate a random password for the database user (16 characters, no special chars)
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Define the Secrets Manager secret that will store DB credentials
resource "aws_secretsmanager_secret" "db_secret" {
  name = "lamp-db-credentials-${random_id.secret_suffix.hex}"
}

# Create a unique suffix to avoid naming collisions in Secrets Manager
resource "random_id" "secret_suffix" {
  byte_length = 4
}


# Set the actual secret value with username, generated password, and DB name
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "lamp_admin"
    password = random_password.db_password.result
    dbname   = var.db_name
  })
}

# Define a DB subnet group using the provided private subnets
resource "aws_db_subnet_group" "lamp_db_subnet" {
  name       = "lamp-db-subnet-group"
  subnet_ids = var.private_subnets
}


# Create a security group for the RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "lamp-rds-sg"
  description = "Allow MySQL access from web servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [var.web_sg_id]
  }

  tags = {
    Name = "lamp-rds-sg"
  }
}


# Create the RDS MySQL database instance
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
