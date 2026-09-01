terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">4.1.0"
    }
  }
backend "azurerm" {
  resource_group_name = "remote-state-rg"
  storage_account_name = "statestorage08"
  container_name = "statecontainer"
  key = "stateremote.tfstate"

}

}




provider "azurerm" {
  features {}
}