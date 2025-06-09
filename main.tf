provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0" # Updated to latest stable version

  name = "lamp-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "rds" {
  source = "./modules/rds"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  db_name        = var.db_name
}

module "web" {
  source = "./modules/web"

  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  db_secret_arn   = module.rds.db_secret_arn
  db_endpoint     = module.rds.db_endpoint
  key_name        = var.key_name
}