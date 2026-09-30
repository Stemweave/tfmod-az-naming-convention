module "naming" {
  source = "../.."

  project_name = "TERRAFORMSTATE"
  type         = "personal"
  environment  = "DEV"
  region       = "eastus"

  resource_types = [
    "resource_group",
    "storage_account",
    "key_vault",
    "virtual_network",
    "virtual_machine_linux",
  ]
}

output "names" {
  value = module.naming.names
}

output "storage_account_was_trimmed" {
  value = module.naming.details["storage_account"].trimmed
}
