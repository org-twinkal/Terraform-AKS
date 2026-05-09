locals {
  name = "aks"
  env  = "test"
  tags = {
    Environment = local.env
    CreatedBy   = "terraform"
  }
  address_space    = ["10.1.0.0/16"]
  address_prefixes = ["10.1.1.0/24"]
}