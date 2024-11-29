terraform {
  backend "azurerm" {
    resource_group_name  = "martinzStateRG"             # Replace with your Resource Group name
    storage_account_name = "martinzterraformstate6"     # Replace with your Storage Account name
    container_name       = "tfstate"                   # Replace with your Blob Container name
    key                  = "terraform.tfstate"         # State file name
  }
}
