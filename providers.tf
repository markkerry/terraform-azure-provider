terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "=3.0.0"
        }
    }
    backend "azurerm" {
        resource_group_name = "rg-eu-stg"
        storage_account_name = "mkstgcqgtckq5sjjds"
        container_name = "tf-state"
        key = "terraform.tfstate"
    }
}

provider "azurerm" {
    subscription_id = "6d02c8ba-0588-4343-aba5-dc2280bd2bcc"
    features {}
}