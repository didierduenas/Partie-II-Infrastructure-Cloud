# Configure the Azure provider
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.14.0"
    }

  }
  # Configure the Microsoft Azure Provider
  required_version = ">= 0.15.3"
}

provider "azurerm" {
  features {}
}
# Create a resource group
resource "azurerm_resource_group" "dev-rg" {
  name     = "DEV-ENVIREMENT-rg"
  location = "France Central"
}

# Create app service plan
resource "azurerm_app_service_plan" "service-plan" {
  name                = "Dolibarr-APP-service"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
  tags = {
    environment = "PROD"
  }
}

# Create BackEnd app service (JAVA )
resource "azurerm_app_service" "app-service" {
  name                = "Dolibarr-wa-BACK"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  app_service_plan_id = azurerm_app_service_plan.service-plan.id

  site_config {
    linux_fx_version = "javaSE"
  }
  tags = {
    environment = "dev"
  }
}
# Create Frontend app service 
resource "azurerm_app_service" "app-service2" {
  name                = "Dolibarr-wa-FRONT"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  app_service_plan_id = azurerm_app_service_plan.service-plan.id

  site_config {
    linux_fx_version = "php7.4"
  }
  tags = {
    environment = "dev"
  }
}

# Create MariaDB MYSQL

resource "azurerm_mysql_server" "dev-rg" {
  name                = "mariabdb"
  location            = "France central"
  resource_group_name = azurerm_resource_group.dev-rg.name

  administrator_login          = "mysqladminun"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}
# Create a K8s 3 Nodes 
# Configuring pods: Groupe of one or more conteiners , shere and run btwn containers 
resource "azurerm_resource_group" "rg" {
  name     = "k8sResourceGroup"
  location = "France Central"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "k8scluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "k8scluster"

  default_node_pool {
    name       = "node1"
    node_count = "2"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "mem" {
 kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
 name                  = "node2"
 node_count            = "1"
 vm_size               = "standard_d11_v2"
}


# ACR Azure container registry  connect with docker 
 # « create Container Registry «  

resource "azurerm_container_registry" "acr" {
  name                = "containerRegistry1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
  
}



# A Service is an abstraction which defines a logical set of pods and a policy by which to access them - sometimes called a micro-service. This data source allows you to pull data about such service.
# Configurating MariaDB services (volumen, backup, config app)
#data "kubernetes_service" "example" {
 # metadata {
   # name = "terraform-example"
  #}
#}

#resource "aws_route53_record" "example" {
  #zone_id = "data.aws_route53_zone.k8.zone_id"
  #name    = "example"
  #type    = "CNAME"
  #ttl     = "300"
  #records = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]
#}

# Configurating Dolibarr service ( 2 repliques : conexion avec mariadb, backup et config )

# Configurating  load balancer  service (load balancer) 






# incluire dans l'angle VARIABLES 
# variable "POC-TERRAFORM-RG" {
   # default = "myTFResourceGroup"
 # }

# Create a resource group 
 # resource "azurerm_resource_group" "rg" {
   # name     = "POC-TERRAFORM-RG"
   # location = "France Central"
   # tags = {
     # Environment = "Terraform Getting Started"
     # Team        = "DevOps"
  #  }
 # }

# Create a virtual network
# resource "azurerm_virtual_network" "vnet" {
  # name                = "myTFVnet"
  # address_space       = ["10.0.0.0/16"]
  # location            = "France Central"
 #  resource_group_name = azurerm_resource_group.rg.name
 #}
# Create a virtual network within the resource group
# resource "azurerm_resource_group" "rg" {
#  name                = "devops-didier-RG"
# resource_group_name = azurerm_resource_group.rg.example
# location            = azurerm_resource_group.rg.FranceCentral
# address_space       = ["10.0.0.0/16"]
# }