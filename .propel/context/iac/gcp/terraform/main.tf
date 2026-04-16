module "networking" {
  source      = "./modules/networking"
  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  vpc_cidr    = var.vpc_cidr
}

module "security" {
  source               = "./modules/security"
  project_id           = var.project_id
  environment          = var.environment
  service_account_name = var.service_account_name
}
