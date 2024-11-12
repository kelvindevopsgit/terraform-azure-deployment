terraform {
  backend "azurerm" {
    resource_group_name   = "martinzexampleResourceGroup3"
    storage_account_name  = "martinzresourcegroup3"
    container_name        = "terraform-state"
    key                   = "terraform.tfstate"
  }
}
