locals {
  naming_prefix = "${lower(var.environment)}-${lower(var.resource_naming_prefix)}"
}