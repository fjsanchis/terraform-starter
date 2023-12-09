#OVH
variable "ovh_endpoint" {
  type        = string
  sensitive   = false
  description = "ovh endpoint"
}

variable "ovh_app_key" {
  type        = string
  sensitive   = true
  description = "ovh application key"
}

variable "ovh_app_secret" {
  type        = string
  sensitive   = true
  description = "ovh application secret"
}

variable "ovh_consumer_key" {
  type        = string
  sensitive   = true
  description = "ovh consumer key"
}

variable "ovh_cloud_project_id" {
  type        = string
  sensitive   = true
  description = "ovh cloud project id"
}
variable "ovh_vrack_id" {
  type        = string
  sensitive   = true
  description = "ovh vrack id"
}

# Openstack 
variable "openstack_user_name" {
  type        = string
  sensitive   = false
  description = "openstack username"
}
variable "openstack_tenant_name" {
  type        = string
  sensitive   = false
  description = "openstack"
}
variable "openstack_password" {
  type        = string
  sensitive   = false
  description = "openstack"
}
variable "openstack_auth_url" {
  type        = string
  sensitive   = false
  description = "openstack"
}
variable "openstack_region" {
  type        = string
  sensitive   = false
  description = "openstack"
}
