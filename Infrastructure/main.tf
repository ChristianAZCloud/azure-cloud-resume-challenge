# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Cloud Resume Challenege Infrastructure 
resource "azurerm_resource_group" "CRC-RG" {
  name     = "cloud-resume-challenge-rg"
  location = var.rg_location

  tags = {
    environment = "production"
  }
}

resource "azurerm_storage_account" "CRC-SA" {
  name                     = var.storage_account_name
  location                 = azurerm_resource_group.CRC-RG.location
  resource_group_name      = azurerm_resource_group.CRC-RG.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  static_website {
    error_404_document = "404.html"
    index_document     = "index.html"
  }


  tags = azurerm_resource_group.CRC-RG.tags
}

resource "azurerm_cdn_profile" "CRC-CDNP" {
  name                = var.azurerm_cdn_profile_name
  location            = azurerm_resource_group.CRC-RG.location
  resource_group_name = azurerm_resource_group.CRC-RG.name
  sku                 = "Standard_Microsoft"

  tags = azurerm_resource_group.CRC-RG.tags
}

resource "azurerm_cdn_endpoint" "CRC-CDNE" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.CRC-CDNP.name
  resource_group_name = azurerm_resource_group.CRC-RG.name
  location            = azurerm_resource_group.CRC-RG.location

  origin {
    name      = "origin"
    host_name = azurerm_storage_account.CRC-SA.primary_web_host
  }

  tags = azurerm_resource_group.CRC-RG.tags
}

resource "azurerm_resource_group" "DNS-RG2" {
  name     = "DNS-RG2"
  location = "eastus"
}

resource "azurerm_dns_zone" "DNSZONE2" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.DNS-RG2.name
}

resource "azurerm_dns_cname_record" "CDN-CNAME-Record" {
  depends_on = [ azurerm_cdn_endpoint.CRC-CDNE ]
  name                = "resume"
  resource_group_name = azurerm_resource_group.DNS-RG2.name
  zone_name           = azurerm_dns_zone.DNSZONE2.name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.CRC-CDNE.id
}

resource "azurerm_cdn_endpoint_custom_domain" "name" {
  depends_on = [ time_sleep.WAIT-60-Seconds ]
  name            = var.cnd_endpoint_custom_domain_name
  host_name       = var.cnd_endpoint_custom_domain_hostname
  cdn_endpoint_id = azurerm_cdn_endpoint.CRC-CDNE.id
  cdn_managed_https {
    certificate_type = var.certificate_type
    protocol_type    = var.protocol_type
    tls_version      = var.tls_version
  }

}

resource "time_sleep" "WAIT-60-Seconds" {
  depends_on = [ azurerm_dns_cname_record.CDN-CNAME-Record ]
  create_duration = "60s"
  # Before running terraform destroy, also use a delete_duration = "60s". I will need to figure out the exact order between the dns zone, endpoint and custom domain. Known issue of delays. 
}
