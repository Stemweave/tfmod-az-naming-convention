variables {
  project_name   = "terraformstate"
  resource_types = ["resource_group"]
  type           = "personal"
  environment    = "dev"
  region         = "eastus"
}

run "returns_the_name_under_the_type_that_was_passed" {
  command = plan

  assert {
    condition     = output.names["resource_group"] == "TERRAFORMSTATE-RG-PSL-DEV-USE"
    error_message = "Expected TERRAFORMSTATE-RG-PSL-DEV-USE, got ${jsonencode(output.names)}"
  }

  assert {
    condition     = keys(output.names) == ["resource_group"]
    error_message = "Only the requested types should be returned, got ${jsonencode(keys(output.names))}"
  }

  assert {
    condition = output.details["resource_group"] == {
      name = "TERRAFORMSTATE-RG-PSL-DEV-USE"
      parts = {
        project_name  = "TERRAFORMSTATE"
        resource_type = "RG"
        type          = "PSL"
        environment   = "DEV"
        region        = "USE"
      }
      trimmed       = false
      max_length    = 90
      unique_within = "subscription"
      verified      = true
    }
    error_message = "details don't match: ${jsonencode(output.details["resource_group"])}"
  }
}

run "names_several_resources_in_one_call" {
  command = plan

  variables {
    resource_types = ["resource_group", "storage_account", "key_vault", "virtual_network"]
  }

  assert {
    condition = output.names == {
      resource_group  = "TERRAFORMSTATE-RG-PSL-DEV-USE"
      storage_account = "terraformstatstpsldevuse"
      key_vault       = "TERRAFORM-KV-PSL-DEV-USE"
      virtual_network = "TERRAFORMSTATE-VNET-PSL-DEV-USE"
    }
    error_message = "Unexpected names: ${jsonencode(output.names)}"
  }
}

run "forces_upper_case" {
  command = plan

  variables {
    project_name = "MixedCase1"
  }

  assert {
    condition     = output.names["resource_group"] == "MIXEDCASE1-RG-PSL-DEV-USE"
    error_message = "Segments should be upper-cased, got ${output.names["resource_group"]}"
  }
}

run "storage_account_is_lower_case_without_hyphens" {
  command = plan

  variables {
    project_name   = "app"
    resource_types = ["storage_account"]
  }

  assert {
    condition     = output.names["storage_account"] == "appstpsldevuse"
    error_message = "Expected appstpsldevuse, got ${output.names["storage_account"]}"
  }

  assert {
    condition     = output.details["storage_account"].trimmed == false
    error_message = "A short name shouldn't be trimmed"
  }
}

run "storage_account_is_trimmed_to_24_characters" {
  command = plan

  variables {
    resource_types = ["storage_account"]
  }

  assert {
    condition     = output.names["storage_account"] == "terraformstatstpsldevuse"
    error_message = "Expected the project name shortened by one character, got ${output.names["storage_account"]}"
  }

  assert {
    condition     = length(output.names["storage_account"]) == 24 && output.details["storage_account"].trimmed
    error_message = "Name should be exactly 24 characters and flagged as trimmed"
  }

  assert {
    condition     = endswith(output.names["storage_account"], "stpsldevuse")
    error_message = "Trimming must keep the resource type, type, environment, and region"
  }
}

run "key_vault_keeps_hyphens_and_trims_the_project" {
  command = plan

  variables {
    resource_types = ["key_vault"]
  }

  assert {
    condition     = output.names["key_vault"] == "TERRAFORM-KV-PSL-DEV-USE"
    error_message = "Expected TERRAFORM-KV-PSL-DEV-USE, got ${output.names["key_vault"]}"
  }

  assert {
    condition     = length(output.names["key_vault"]) == 24
    error_message = "Key vault names are limited to 24 characters"
  }
}

run "container_registry_has_no_hyphens" {
  command = plan

  variables {
    project_name   = "app"
    resource_types = ["container_registry"]
  }

  assert {
    condition     = output.names["container_registry"] == "APPCRPSLDEVUSE"
    error_message = "Registry names allow no hyphens but aren't forced to lower case, got ${output.names["container_registry"]}"
  }
}

run "returns_the_key_as_the_caller_wrote_it" {
  command = plan

  variables {
    project_name   = "app"
    resource_types = ["Storage Account", "key-vault"]
  }

  assert {
    condition     = output.names["Storage Account"] == "appstpsldevuse" && output.names["key-vault"] == "APP-KV-PSL-DEV-USE"
    error_message = "Other spellings should work and be returned under the key passed, got ${jsonencode(output.names)}"
  }
}

run "unverified_types_still_build_a_name_and_warn" {
  command = plan

  variables {
    resource_types = ["nat_gateway"]
  }

  expect_failures = [check.resource_type_rules]
}

run "custom_types_add_to_the_list" {
  command = plan

  variables {
    resource_types = ["widget"]
    custom_resource_types = {
      widget = { code = "wd", max_length = 20, lowercase = true, hyphens = false }
    }
  }

  assert {
    condition     = output.names["widget"] == "terraformwdpsldevuse" && length(output.names["widget"]) == 20
    error_message = "Custom type should apply its own rules, got ${output.names["widget"]}"
  }

  assert {
    condition     = output.details["widget"].verified
    error_message = "A custom type is the caller's own rule, so it shouldn't warn"
  }
}

run "custom_types_can_replace_a_built_in_rule" {
  command = plan

  variables {
    resource_types = ["storage_account"]
    custom_resource_types = {
      storage_account = { code = "sa", max_length = 30, lowercase = true, hyphens = false }
    }
  }

  assert {
    condition     = output.names["storage_account"] == "terraformstatesapsldevuse"
    error_message = "The custom rule should win over the built-in one, got ${output.names["storage_account"]}"
  }
}

run "rejects_an_unknown_resource_type" {
  command = plan

  variables {
    resource_types = ["resource_group", "storage_acount"]
  }

  expect_failures = [var.resource_types]
}

run "rejects_an_empty_list" {
  command = plan

  variables {
    resource_types = []
  }

  expect_failures = [var.resource_types]
}

run "rejects_the_whole_call_when_one_name_cannot_be_valid" {
  command = plan

  variables {
    project_name   = "1app"
    resource_types = ["resource_group", "key_vault"]
  }

  expect_failures = [output.names]
}

run "rejects_a_fixed_part_that_alone_is_too_long" {
  command = plan

  variables {
    resource_types = ["tiny"]
    custom_resource_types = {
      tiny = { code = "t", max_length = 8 }
    }
  }

  expect_failures = [output.names]
}

run "rejects_a_name_below_the_minimum_length" {
  command = plan

  variables {
    project_name   = "a"
    resource_types = ["big"]
    custom_resource_types = {
      big = { code = "b", min_length = 40, max_length = 63 }
    }
  }

  expect_failures = [output.names]
}

run "maps_location_spellings_to_the_same_code" {
  command = plan

  variables {
    region = "East US"
  }

  assert {
    condition     = output.details["resource_group"].parts.region == "USE"
    error_message = "\"East US\" should map to USE"
  }
}

run "maps_other_locations" {
  command = plan

  variables {
    region = "westeurope"
  }

  assert {
    condition     = output.names["resource_group"] == "TERRAFORMSTATE-RG-PSL-DEV-EUW"
    error_message = "westeurope should map to EUW, got ${output.names["resource_group"]}"
  }
}

run "uses_a_capitalised_short_code_as_given" {
  command = plan

  variables {
    region = "USE"
  }

  assert {
    condition     = output.details["resource_group"].parts.region == "USE"
    error_message = "A short code should be kept"
  }
}

run "rejects_a_lower_case_word_that_is_not_a_location" {
  command = plan

  variables {
    region = "estus"
  }

  expect_failures = [var.region]
}

run "region_codes_override_the_built_in_table" {
  command = plan

  variables {
    region_codes = {
      eastus = "EU1"
    }
  }

  assert {
    condition     = output.details["resource_group"].parts.region == "EU1"
    error_message = "region_codes should win over the built-in table"
  }
}

run "adds_a_location_the_table_lacks" {
  command = plan

  variables {
    region       = "Chile Central"
    region_codes = { chilecentral = "clc" }
  }

  assert {
    condition     = output.details["resource_group"].parts.region == "CLC"
    error_message = "An added location should map to its code"
  }
}

run "rejects_an_unknown_location" {
  command = plan

  variables {
    region = "mars-north-1"
  }

  expect_failures = [var.region]
}

run "rejects_hyphens_in_project_name" {
  command = plan

  variables {
    project_name = "terraform-state"
  }

  expect_failures = [var.project_name]
}

run "rejects_an_empty_environment" {
  command = plan

  variables {
    environment = ""
  }

  expect_failures = [var.environment]
}

run "rejects_a_bad_region_code_override" {
  command = plan

  variables {
    region_codes = { eastus = "TOOLONGCODE" }
  }

  expect_failures = [var.region_codes]
}

run "rejects_an_invalid_custom_type" {
  command = plan

  variables {
    custom_resource_types = {
      bad = { code = "b", min_length = 10, max_length = 5 }
    }
  }

  expect_failures = [var.custom_resource_types]
}

run "maps_a_type_name_to_its_code" {
  command = plan

  variables {
    type = "work"
  }

  assert {
    condition     = output.names["resource_group"] == "TERRAFORMSTATE-RG-WRK-DEV-USE"
    error_message = "work should map to WRK, got ${output.names["resource_group"]}"
  }
}

run "accepts_other_spellings_of_a_type_name" {
  command = plan

  variables {
    type = "Personal"
  }

  assert {
    condition     = output.details["resource_group"].parts.type == "PSL"
    error_message = "Personal should map to PSL"
  }
}

run "uses_a_capitalised_type_code_as_given" {
  command = plan

  variables {
    type = "OPS"
  }

  assert {
    condition     = output.details["resource_group"].parts.type == "OPS"
    error_message = "A code in capitals should be kept"
  }
}

run "rejects_a_lower_case_word_that_is_not_a_type" {
  command = plan

  variables {
    type = "persnal"
  }

  expect_failures = [var.type]
}

run "type_codes_add_a_type" {
  command = plan

  variables {
    type       = "client"
    type_codes = { client = "CLT" }
  }

  assert {
    condition     = output.names["resource_group"] == "TERRAFORMSTATE-RG-CLT-DEV-USE"
    error_message = "An added type should map to its code, got ${output.names["resource_group"]}"
  }
}

run "type_codes_can_replace_a_built_in_type" {
  command = plan

  variables {
    type       = "personal"
    type_codes = { personal = "HOM" }
  }

  assert {
    condition     = output.details["resource_group"].parts.type == "HOM"
    error_message = "type_codes should win over the built-in table"
  }
}

run "type_code_follows_the_resource_case" {
  command = plan

  variables {
    resource_types = ["storage_account"]
    type           = "work"
  }

  assert {
    condition     = output.names["storage_account"] == "terraformstatstwrkdevuse"
    error_message = "Storage accounts are lower case, got ${output.names["storage_account"]}"
  }
}

run "rejects_a_bad_type_code_override" {
  command = plan

  variables {
    type_codes = { client = "TOOLONGCODE" }
  }

  expect_failures = [var.type_codes]
}

run "rejects_a_type_name_that_is_not_lower_case" {
  command = plan

  variables {
    type_codes = { Client = "CLT" }
  }

  expect_failures = [var.type_codes]
}
