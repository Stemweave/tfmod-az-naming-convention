variable "project_name" {
  description = "Project or workload name, the first segment of the name. Example: TERRAFORMSTATE. Shortened if the name would exceed the resource's length limit."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.project_name))
    error_message = "project_name must be letters and digits only, with no hyphens or spaces."
  }
}

variable "resource_types" {
  description = "The Azure resources to name, as keys from docs/resource-types.md. Example: [\"resource_group\", \"storage_account\"]. A name is returned for each, under the same key."
  type        = set(string)

  validation {
    condition     = length(var.resource_types) > 0
    error_message = "resource_types needs at least one resource type."
  }

  validation {
    condition     = alltrue([for t in var.resource_types : contains(keys(local.resource_types), lower(replace(replace(trimspace(t), " ", "_"), "-", "_")))])
    error_message = "Unknown resource types: ${join(", ", [for t in var.resource_types : "\"${t}\"" if !contains(keys(local.resource_types), lower(replace(replace(trimspace(t), " ", "_"), "-", "_")))])}. Use keys from docs/resource-types.md, such as resource_group or storage_account, or define them in custom_resource_types."
  }
}

variable "type" {
  description = "What the resources are for, the third segment of the name. A name from the table in type_codes.tf, such as personal or work, which is mapped to its code, or a code in capitals such as PSL, which is used as it is."
  type        = string

  validation {
    condition     = contains(keys(local.type_codes), lower(replace(replace(replace(var.type, " ", ""), "-", ""), "_", ""))) || can(regex("^[A-Z0-9]{2,6}$", var.type))
    error_message = "Unknown type \"${var.type}\". Use one of: ${join(", ", sort(keys(local.type_codes)))}, or a code in capitals (2 to 6 letters or digits), or add it to type_codes."
  }
}

variable "type_codes" {
  description = "Extra or replacement types, as name to code, for example { client = \"CLT\" }. Names are lower case letters and digits. Merged over the table in type_codes.tf."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for name in keys(var.type_codes) : can(regex("^[a-z0-9]+$", name))])
    error_message = "type_codes names must be lower case letters and digits only."
  }

  validation {
    condition     = alltrue([for code in values(var.type_codes) : can(regex("^[A-Za-z0-9]{2,6}$", code))])
    error_message = "Every type code must be 2 to 6 letters or digits."
  }
}

variable "environment" {
  description = "Environment code. Example: DEV, TST, PRD."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9]+$", var.environment))
    error_message = "environment must be letters and digits only, with no hyphens or spaces."
  }
}

variable "region" {
  description = "Azure location such as eastus or \"East US\", which is mapped to its short code, or a short code in capitals such as USE, which is used as it is."
  type        = string

  validation {
    condition     = contains(keys(local.region_codes), lower(replace(replace(var.region, " ", ""), "-", ""))) || can(regex("^[A-Z0-9]{2,6}$", var.region))
    error_message = "Unknown region \"${var.region}\". Use a known Azure location, a short code in capitals (2 to 6 letters or digits), or add the location to region_codes."
  }
}

variable "region_codes" {
  description = "Extra or replacement short codes for Azure locations, keyed by location name in lower case without spaces. Merged over the built-in table."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for code in values(var.region_codes) : can(regex("^[A-Za-z0-9]{2,6}$", code))])
    error_message = "Every region code must be 2 to 6 letters or digits."
  }
}

variable "custom_resource_types" {
  description = "Resource types to add to the built-in list, or to replace it, keyed by name in lower case with underscores. Use it for a type that isn't listed, or to correct a rule."
  type = map(object({
    code               = string
    min_length         = optional(number, 1)
    max_length         = optional(number, 63)
    lowercase          = optional(bool, false)
    hyphens            = optional(bool, true)
    starts_with_letter = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for key in keys(var.custom_resource_types) : can(regex("^[a-z0-9_]+$", key))])
    error_message = "custom_resource_types keys must be lower case letters, digits, and underscores."
  }

  validation {
    condition     = alltrue([for t in values(var.custom_resource_types) : can(regex("^[A-Za-z0-9]+$", t.code))])
    error_message = "Each custom resource type's code must be letters and digits only."
  }

  validation {
    condition     = alltrue([for t in values(var.custom_resource_types) : t.min_length >= 1 && t.min_length <= t.max_length])
    error_message = "Each custom resource type needs 1 <= min_length <= max_length."
  }
}
