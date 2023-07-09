
###########################
## Azure Provider - Main ##
###########################

# Define Terraform provider
terraform {
  required_version = ">= 0.14"
    required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "str-terraform"
    storage_account_name = "strterraform"
    container_name       = "backend"
    key                  = "terraform.tfstate"
  }
}

# Configure the Azure provider
provider "azurerm" { 

  features {
    resource_group {
    prevent_deletion_if_contains_resources = false
     }
  }
}