run "every_listed_type_produces_a_name_that_obeys_its_own_rules_with_a_long_project_name" {
  command = plan

  module {
    source = "./tests/all_types"
  }

  variables {
    project_name = "averylongprojectnamethatforcestrimming"
  }

  assert {
    condition     = alltrue([for k, name in output.names : length(name) <= output.rules[k].max_length])
    error_message = "A name is longer than its type allows: ${jsonencode([for k, name in output.names : k if length(name) > output.rules[k].max_length])}"
  }

  assert {
    condition     = alltrue([for k, name in output.names : length(name) >= output.rules[k].min_length])
    error_message = "A name is shorter than its type allows: ${jsonencode([for k, name in output.names : k if length(name) < output.rules[k].min_length])}"
  }

  assert {
    condition     = alltrue([for k, name in output.names : output.rules[k].lowercase ? name == lower(name) : name == upper(name)])
    error_message = "A name has the wrong case for its type"
  }

  assert {
    condition     = alltrue([for k, name in output.names : output.rules[k].hyphens || !strcontains(name, "-")])
    error_message = "A name has hyphens where its type forbids them: ${jsonencode([for k, name in output.names : k if !output.rules[k].hyphens && strcontains(name, "-")])}"
  }

  assert {
    condition     = alltrue([for k, name in output.names : !output.rules[k].starts_with_letter || can(regex("^[A-Za-z]", name))])
    error_message = "A name doesn't start with a letter where its type requires one"
  }

  assert {
    condition     = alltrue([for k, name in output.names : endswith(replace(lower(name), "-", ""), "psldevuse")])
    error_message = "Trimming must never cut the type, environment, or region"
  }
}

run "every_listed_type_also_works_with_a_short_project_name" {
  command = plan

  module {
    source = "./tests/all_types"
  }

  variables {
    project_name = "app"
  }

  assert {
    condition     = alltrue([for k, name in output.names : length(name) >= output.rules[k].min_length && length(name) <= output.rules[k].max_length])
    error_message = "A name is outside its type's length range"
  }
}

run "only_types_with_tiny_limits_are_left_out" {
  command = plan

  module {
    source = "./tests/all_types"
  }

  variables {
    project_name = "app"
  }

  assert {
    condition     = alltrue([for k, max in output.too_short_for_the_convention : max <= 18])
    error_message = "A type with room for the fixed part was left out: ${jsonencode(output.too_short_for_the_convention)}"
  }
}
