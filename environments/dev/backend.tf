terraform {
  backend "azurerm" {
    resource_group_name = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "terraform-state"
    key                  = "dev/terraform.tfstate"
  }
}
