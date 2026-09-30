output "names" {
  description = "The name for each requested resource type, keyed as it was passed in: names[\"resource_group\"]. Each is valid for its resource type in case, hyphens, and length."
  value       = local.names

  precondition {
    condition     = length(local.problems) == 0
    error_message = "Can't build a valid name:\n${join("\n", local.problems)}"
  }
}

output "details" {
  description = "For each requested resource type: the name, its segments, whether project_name was shortened, the longest name allowed, where the name must be unique, and whether Microsoft's published rules were used."
  value = {
    for t, r in local.rules : t => {
      name          = local.names[t]
      parts         = local.parts[t]
      trimmed       = local.project[t] != var.project_name
      max_length    = r.max_length
      unique_within = r.scope
      verified      = r.verified
    }
  }
}

output "supported_resource_types" {
  description = "Every resource type the module knows, including custom ones, with its code and rules. The keys are what resource_types accepts."
  value       = local.resource_types
}
