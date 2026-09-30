variable "project_name" {
  type = string
}

# Reads the module's own list of types, so the test always covers whatever the module ships.
module "catalog" {
  source = "../.."

  project_name   = "app"
  resource_types = ["resource_group"]
  type           = "personal"
  environment    = "DEV"
  region         = "eastus"
}

locals {
  all_types = { for key, t in module.catalog.supported_resource_types : key => t if t.verified }

  # The fixed part is the code, type, environment, and region, plus four hyphens where allowed.
  fixed_length = { for key, t in local.all_types : key => length(t.code) + 9 + (t.hyphens ? 4 : 0) }
  types        = { for key, t in local.all_types : key => t if t.max_length - local.fixed_length[key] >= 1 }
}

module "naming" {
  source = "../.."

  project_name   = var.project_name
  resource_types = keys(local.types)
  type           = "personal"
  environment    = "DEV"
  region         = "eastus"
}

output "names" {
  value = module.naming.names
}

output "rules" {
  value = local.types
}

output "too_short_for_the_convention" {
  value = { for key, t in local.all_types : key => t.max_length if !contains(keys(local.types), key) }
}
