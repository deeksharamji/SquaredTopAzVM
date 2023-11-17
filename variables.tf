variable "node_location" {
type = string
}

variable "resource_prefix" {
type = string
}

variable "node_address_space" {
default = ["10.0.0.0/16"]
}

#variable for network range

variable "node_address_prefix" {
#default = "10.0.1.0/24"
}

#variable for Environment
variable "Environment" {
type = string
}

variable "node_count" {
type = number
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
 }

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
 }