module "vpc" {
  source               = "./modules/vpc"
  project              = var.project
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_vpc_flow_logs = var.enable_vpc_flow_logs
}

module "ec2" {
  source          = "./modules/ec2"
  project         = var.project
  subnet_id       = module.vpc.public_subnet_ids[0]
  vpc_id          = module.vpc.vpc_id
  allowed_ssh_cidr= var.allowed_ssh_cidr
  key_name        = var.key_name
  instance_type   = var.instance_type
}
