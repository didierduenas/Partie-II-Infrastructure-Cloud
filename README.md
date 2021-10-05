
#  Démonstration pour la Partie II

![image](https://user-images.githubusercontent.com/71215691/136080553-316eefc9-2b57-4c4d-aa4c-019d70759b6f.png)

Détruire l’un des pods
Montrer que le service continue à fonctionner
Montrer que la seconde réplique du Pod est revenue
-----------------------------------------------------

Le contrôleur Application Gateway Ingress permet d’utiliser la passerelle Azure Application Gateway comme entrée pour un cluster Azure Kubernetes Service alias AKS. Comme le montre la figure ci-dessus, le contrôleur d’entrée fonctionne comme un module dans le cluster AKS. Il consomme Kubernetes Ingress Resources et les convertit en une configuration Azure Application Gateway qui permet à la passerelle d’équilibrer le trafic vers les pods Kubernetes.

Ce module aide à déployer les ressources nécessaires pour le déploiement en champ vierge des ressources nécessaires pour le cluster AKS avec Application Gateway comme contrôleur d’entrée.

Les pods sont configurées avec l'algorithmes de répartition de charge Round-robin (Requête envoyé au serveur 1  puis  2 … n) .
![image](https://user-images.githubusercontent.com/71215691/136083823-fd29d96c-f876-4c5a-9397-d57d1b450b4a.png)



Usage of the module
# Configure the Azure provider
# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
###### terraform {
######   required_providers {
######     azurerm = {
######       source  = "hashicorp/azurerm"
######       version = "~> 2.14.0"
######     }

######   }
######   # Configure the Microsoft Azure Provider
######   required_version = ">= 0.15.3"
###### }

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


# Deploying the necessary resources for the greenfield deployment of necessary resources for AKS cluster with Application Gateway as ingress controlle

module "appgw-ingress-k8s-cluster" {
  source                              = "Azure/appgw-ingress-k8s-cluster/azurerm"
  version                             = "0.1.0"
  resource_group_name                 = azurerm_resource_group.rg.name
  location                            = azurerm_resource_group.rg.location
  aks_service_principal_app_id        = "<App ID of the service principal>"
  aks_service_principal_client_secret = "<Client secret of the service principal>"
  aks_service_principal_object_id     = "<Object ID of the service principal>"

  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

  


# Partie-II-Infrastructure-Cloud
Docker, dockerhub, service Dolibarr, déploiement continu Gitlab , kubernetes
Mots-cléfs : docker, déploiement continu, kubernetes

Préparation des images
Le travail se fera dans un dépots Git distinct du premier.

Nous allons chercher à créer une image pour le service Dolibarr.

Pour chaque service, écrire les scripts et configuration (Dockerfile, docker-compose.yml, etc.) permettant de :

créer une image docker
vérifier son bon fonctionnement
pousser cette image en ligne sur DockerHub.
Notez que cette image:

doit être basées sur Debian Buster 64 bits
doit intégrer Apache2 et PHP 7 et les modules nécessaires à Dolibarr
dépend d’un container MariaDB indépendant pour fonctionner
Préparation de l’infrastructure
Créer un cluster Kubernetes avec 3 noeuds

soit sur un opérateur Cloud de votre choix (Digital Ocean, Linode, OVH, Azure, AWS, GCP, etc)
soit installé on-premises (pour les plus motivés)
sur des serveurs VPS
ou sur des VM Vagrant
Attention: la version on-premises sera plus compliquée à gérer pour le load-balancing.

Déploiement
Ecrire la configuration Kubernetes permettant de déployer le services suivants :

MariaDB
sur une seule réplique ;
avec les bons volumes pour sauver les données et la configuration de l’application ;
Dolibarr
sur 2 répliques
paramétré pour se connecter sur MariaDB ;
avec les bons volumes pour sauver les données et la configuration de l’application ;
un load balancer permettra de balancer les requêtes entrantes d’une réplique à l’autre (round-robin).
Déploiement continu
Utiliser un outil de déploiement continu (Jenkins, Travis, CircleCI, Gitlab-CI, etc) connecté à votre dépot Git de telle sorte que

chaque git push déclanche le rebuild des images concernées ;
si le build de l’image réussi, alors la nouvelle version de l’image est déployée sur votre cluster.
Points Bonus
Mise en place d’un systeme de monitoring pour surveiller l’état de santé de vos serveur ou de vos services
Utilisation d’outils DevOps qui n’ont pas été vus dans le cadre du cursus (ex: Terraform ou Packer)
Automatisation de vos démonstrations
Documentation de votre procédure de test pour valider chaque étape
Méthodologie
Organisation
Le projet sera réalisé en équipes de deux ou trois personnes.

Vous vous organiserez pour distribuer les taches afin que tout le monde participe aux deux parties du projet.

L’utilisation d’un outil de gestion de projet (gitlab, trello, etc.) sera fortement apprécié.

Note: à trois, donnez-vous à fond pour faire quelques élements bonus également.

Suivi et questions
Vous pouvez envoyer un email avec vos questions à teaching@glenux.net. Ce mail devra indiquer [DEVOPS FITEC] QUESTION dans le titre.

Une réponse sera fournie lors de la prochaine journée de suivi/accompagnement de projet.

Rendu du projet
Le rendu sera fait par l’envoi d’un email, à destination de teaching@glenux.net. Ce mail devra indiquer [DEVOPS FITEC] RENDU FINAL dans le titre.

Cet email listera les membres de votre groupe (nom, prénom & email)

Il devra également fournir les liens vers vos deux dépots GIT publics (distincts pour chaque partie).

Chaque dépot GIT contiendra un fichier README.md qui documentera votre démarche et expliquera étape par étape comment utiliser vos scripts pour obtenir l’infrastructure demandée dans ce projet.

Soutenance
Durant la soutenance vous présenterez au jury le projet, ses enjeux et l’apport votre travail.

Vous expliquerez plus particulierement votre démarche de travail, l’organisation du projet et les différents points techniques (avec schéma, documentation, etc.)

Vous ferez la démonstration du bon fonctionnement de chacune des infrastructures que vous avez conçu. Le détail des démonstration attendues est précisé ci-dessous.

Vous pouvez utiliser un support de présentation (ex: diaporama).




