terraform {
  backend "azurerm" {
    resource_group_name   = "martinzexampleResourceGroup5"
    storage_account_name  = "martinzresourcegroup5"
    container_name        = "terraform-state"
    key                   = "terraform.tfstate"
  }
}
