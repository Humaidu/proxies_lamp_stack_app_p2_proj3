# ──────── Provider Configuration ────────

# Set the AWS provider region to EU (Ireland)
provider "aws" {
  region = "eu-west-1"
}

# ──────── VPC Module ────────

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" # Use the latest stable version of the VPC module

  name = "lamp-vpc"
  cidr = "10.0.0.0/16" # Base CIDR block for the entire VPC

  # Define Availability Zones
  azs             = ["eu-west-1a", "eu-west-1b"]

  # Define subnet ranges
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # Enable NAT Gateway for internet access in private subnets
  enable_nat_gateway = true
  single_nat_gateway = true
}

# ──────── RDS Module ────────

module "rds" {
  source = "./modules/rds"

  # Pass in VPC and subnet info
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  # Pass in DB name and web security group
  db_name   = var.db_name
  web_sg_id = module.web.web_sg_id
}

# ──────── Web Server Module ────────

module "web" {
  source = "./modules/web"

  # Networking details
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets

  # Secrets and database endpoint for connecting PHP to RDS
  db_secret_arn = module.rds.db_secret_arn
  db_endpoint   = module.rds.db_endpoint

  # SSH key for EC2 access
  key_name = var.key_name

  # Project tag for resource identification
  project_name = var.project_name

  instance_profile_name = "lamp-stack-app-ec2-profile"

}

# ──────── Monitoring Module (e.g., CloudWatch) ────────

module "monitoring" {
  source                  = "./modules/monitoring"
  project_name            = var.project_name

  # Reference to the Auto Scaling Group name in the web module
  aws_autoscaling_group = module.web.asg_name
}
