##########################################
## Azure Network - Variables ##
##########################################

variable "app_name" {
  type        = string
  description = "Applciation name"
}

variable "environment" {
  type        = string
  description = "Environment name where the resources will be deployed"
}

variable "location" {
  type        = string
  description = "Location name where the resources will be deployed"
}


variable "network-app-vnet-cidr" {
  type        = string
  description = "CIDR range of application vnet"
}

variable "network-bastion-subnet-cidr" {
  type        = string
  description = "CIDR range of bastion subnet"
}



variable "network-app-subnet-cidr" {
  type        = string
  description = "CIDR range of application subnet"
}


variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "aks_service_principal_app_id" {
  type        = string
}

variable "aks_service_principal_client_secret" {
  type        = string
}

variable "vm_password" {
  type        = string
}