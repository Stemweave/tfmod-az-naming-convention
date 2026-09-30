locals {
  region_codes = merge(local.default_region_codes, var.region_codes)
  region_key   = lower(replace(replace(var.region, " ", ""), "-", ""))
  region_code  = upper(lookup(local.region_codes, local.region_key, var.region))

  type_codes = merge(local.default_type_codes, var.type_codes)
  type_key   = lower(replace(replace(replace(var.type, " ", ""), "-", ""), "_", ""))
  type_code  = upper(lookup(local.type_codes, local.type_key, var.type))

  custom_resource_types = {
    for key, t in var.custom_resource_types : key => {
      code               = t.code
      scope              = ""
      verified           = true
      min_length         = t.min_length
      max_length         = t.max_length
      lowercase          = t.lowercase
      hyphens            = t.hyphens
      starts_with_letter = t.starts_with_letter
    }
  }
  resource_types = merge(local.builtin_resource_types, local.custom_resource_types)

  # Each requested type, keyed as the caller wrote it, with its rule.
  rules = {
    for t in var.resource_types : t => local.resource_types[lower(replace(replace(trimspace(t), " ", "_"), "-", "_"))]
  }

  separator = { for t, r in local.rules : t => r.hyphens ? "-" : "" }
  tail      = { for t, r in local.rules : t => "${local.separator[t]}${join(local.separator[t], [r.code, local.type_code, var.environment, local.region_code])}" }

  project_budget = { for t, r in local.rules : t => r.max_length - length(local.tail[t]) }
  project = {
    for t, r in local.rules : t => substr(var.project_name, 0, max(0, min(length(var.project_name), local.project_budget[t])))
  }

  parts = {
    for t, r in local.rules : t => {
      for k, v in {
        project_name  = local.project[t]
        resource_type = r.code
        type          = local.type_code
        environment   = var.environment
        region        = local.region_code
      } : k => r.lowercase ? lower(v) : upper(v)
    }
  }

  names = {
    for t, r in local.rules : t => join(local.separator[t], [
      local.parts[t].project_name,
      local.parts[t].resource_type,
      local.parts[t].type,
      local.parts[t].environment,
      local.parts[t].region,
    ])
  }

  problems = flatten([
    for t, r in local.rules : compact([
      local.project_budget[t] < 1 ? "\"${t}\" allows ${r.max_length} characters, and the type, environment, and region alone take ${length(local.tail[t])}. Shorten them, or set a higher max_length in custom_resource_types." : "",
      local.project_budget[t] >= 1 && length(local.names[t]) < r.min_length ? "\"${t}\" needs at least ${r.min_length} characters but \"${local.names[t]}\" has ${length(local.names[t])}. Use a longer project_name." : "",
      r.starts_with_letter && !can(regex("^[A-Za-z]", local.names[t])) ? "\"${t}\" must start with a letter, but \"${local.names[t]}\" doesn't. Start project_name with a letter." : "",
    ])
  ])

  unverified = sort([for t, r in local.rules : t if !r.verified])
}

check "resource_type_rules" {
  assert {
    condition     = length(local.unverified) == 0
    error_message = "Microsoft doesn't publish naming rules for ${join(", ", local.unverified)}, so the defaults are used (1 to 63 characters, hyphens allowed). Check their limits, or set them in custom_resource_types."
  }
}
