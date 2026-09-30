# tfmod-az-naming-convention

Names your Azure resources in one standard form. Pass the resources you need, and get back a name
for each, already valid for its kind of resource.

```
<PROJECTNAME>-<RESOURCE_TYPE>-<TYPE>-<ENVIRONMENT>-<REGION>
```

For example `TERRAFORMSTATE-RG-PSL-DEV-USE`:

| segment | example | comes from |
|---|---|---|
| project name | `TERRAFORMSTATE` | `project_name` |
| resource type | `RG` | each entry in `resource_types`, looked up in the [resource list](docs/resource-types.md) |
| type | `PSL` | `type = "personal"`, looked up in [type_codes.tf](type_codes.tf) |
| environment | `DEV` | `environment` |
| region | `USE` | `region`, mapped to a short code |

The module creates no resources and needs no provider, so it plans offline.

## Usage

Call the module once and list every resource you want a name for:

```hcl
module "naming" {
  source = "git::https://github.com/<org>/tfmod-naming-convention.git?ref=v1.0.0"

  project_name = var.project_name
  type         = var.type
  environment  = var.environment
  region       = var.location

  resource_types = ["resource_group", "storage_account", "key_vault"]
}

resource "azurerm_resource_group" "this" {
  name     = module.naming.names["resource_group"]
  location = var.location
}

resource "azurerm_storage_account" "this" {
  name = module.naming.names["storage_account"]
  # ...
}
```

`names` is a map with one entry for each type you passed:

```
names = {
  "key_vault"       = "TERRAFORM-KV-PSL-DEV-USE"
  "resource_group"  = "TERRAFORMSTATE-RG-PSL-DEV-USE"
  "storage_account" = "terraformstatstpsldevuse"
}
```

You never format a name yourself. A runnable version is in [examples/basic](examples/basic).

## How each name is fitted to its resource

Every resource type in the [list](docs/resource-types.md) has its own rules, and the module applies
them:

- **Case.** Resources that require lower case get a lower-case name. Everything else is upper case.
- **Hyphens.** Resources that don't allow hyphens get the segments joined with none.
- **Length.** If the name is longer than the resource allows, `project_name` is shortened, and only
  `project_name`. The resource type, type, environment, and region are never cut, so a trimmed name
  still says what it is and where it lives.

| resource type | limits | name for `TERRAFORMSTATE` |
|---|---|---|
| `resource_group` | up to 90 | `TERRAFORMSTATE-RG-PSL-DEV-USE` |
| `storage_account` | 3 to 24, lower case, no hyphens | `terraformstatstpsldevuse` |
| `key_vault` | 3 to 24, must start with a letter | `TERRAFORM-KV-PSL-DEV-USE` |
| `container_registry` | 5 to 50, no hyphens | `TERRAFORMSTATECRPSLDEVUSE` |

The `details` output says when `project_name` was shortened. Trimming can make two projects with a
similar start produce the same name, and some names must be unique across all of Azure (see
`unique_within`), so check the result for resources like storage accounts.

If any requested name can't be made valid, the module stops at plan time and lists each problem:

- the fixed part alone is longer than the limit (see [Limits](#limits))
- the name is shorter than the resource's minimum
- the resource must start with a letter and `project_name` starts with a digit

## Resource types

[docs/resource-types.md](docs/resource-types.md) lists every supported type with its abbreviation
and rules. Put the key from the first column in `resource_types`. Spellings like `Storage Account`
and `storage-account` also work, and the name is returned under whatever key you wrote.

The list covers 221 types. The abbreviations come from Microsoft's
[Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations),
and the rules come from Microsoft's
[naming rules and restrictions](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules).

- **Verified (157 types).** Microsoft publishes rules and the module uses them.
- **Unverified (64 types).** Microsoft publishes an abbreviation but no naming rules, for example
  `nat_gateway`. The module builds a name with defaults (1 to 63 characters, hyphens allowed) and
  prints a warning naming them. Look up the real limits and set them with `custom_resource_types`.

Some resources have different limits per operating system. `virtual_machine` uses the stricter
Windows limit of 15 characters; use `virtual_machine_linux` (64) or `virtual_machine_windows`
explicitly when you know which you have. The same goes for `virtual_machine_scale_set` and the AKS
node pools.

### A type that isn't listed, or a rule that's wrong

```hcl
module "naming" {
  source = "..."

  project_name = "TERRAFORMSTATE"
  type         = "personal"
  environment  = "DEV"
  region       = "eastus"

  resource_types = ["widget"]

  custom_resource_types = {
    widget = {
      code       = "wd"
      max_length = 20
      lowercase  = true
      hyphens    = false
    }
  }
}
```

A custom entry with the same key as a built-in one replaces it. The options are `code` (required),
`min_length` (default 1), `max_length` (default 63), `lowercase` (default false), `hyphens`
(default true), and `starts_with_letter` (default false).

## Inputs

| name | description | default |
|---|---|---|
| `project_name` | Project or workload name. Shortened per resource if the name is too long | required |
| `resource_types` | The resources to name, as keys from [the list](docs/resource-types.md), such as `["resource_group", "storage_account"]` | required |
| `type` | What the resources are for: a name from [type_codes.tf](type_codes.tf) such as `personal` or `work`, or a code in capitals such as `PSL` | required |
| `type_codes` | Extra or replacement types, as name to code | `{}` |
| `environment` | Environment code, such as `DEV`, `TST`, `PRD` | required |
| `region` | An Azure location (`eastus`, `East US`) or a short code in capitals (`USE`) | required |
| `region_codes` | Extra or replacement location codes, keyed by lower-case location name without spaces | `{}` |
| `custom_resource_types` | Resource types to add or replace | `{}` |

`project_name` and `environment` accept letters and digits only. Hyphens are rejected
because they separate the segments, and keeping them out means a name can always be split back into
its parts.

## Outputs

| name | meaning |
|---|---|
| `names` | map from each requested type to its finished name, valid for that resource type |
| `details` | for each requested type: `name`, `parts` (each segment as used), `trimmed`, `max_length`, `unique_within`, and `verified` |

For example `module.naming.details["storage_account"].trimmed` is `true` when the project name had
to be shortened, and `.verified` is `false` when the module used default rules.

## Types

`type` says what the resources are for, and becomes the third segment of the name. Pass a name and
the module looks up its code in [type_codes.tf](type_codes.tf):

| `type` | code in the name |
|---|---|
| `personal` | `PSL` |
| `work` | `WRK` |

Names are not case sensitive, so `Personal` works too. A code in capitals, such as `OPS`, is used as
it is. A lower-case word that isn't in the table is rejected, so a typo such as `persnal` fails at
plan time.

To add a type for good, add a line to `default_type_codes` in [type_codes.tf](type_codes.tf). To add
or change one for a single project, pass `type_codes` without touching the module:

```hcl
type = "client"

type_codes = {
  client = "CLT"
}
```

A name in `type_codes` with the same key as a built-in one replaces it. Names are lower case letters
and digits, and codes are 2 to 6 letters or digits.

## Regions

`region` is an Azure location name, in any spelling that reduces to the same letters
(`eastus`, `East US`, `east-us`), or a short code you already have, written in capitals. Locations
map through the table in [regions.tf](regions.tf), for example `eastus` to `USE`, `westeurope` to
`EUW`, and `uksouth` to `UKS`.

The codes in that table are this module's convention, not an Azure standard. To change one or add a
location that isn't listed, pass `region_codes`:

```hcl
region_codes = {
  eastus       = "EU1"
  chilecentral = "CLC"
}
```

A lower-case word that isn't a known location is rejected, so a typo such as `estus` fails at plan
time instead of becoming a region code.

## Limits

The type, environment, and region take a fixed number of characters: for example
`-RG-PSL-DEV-USE` is 15. A resource whose limit is smaller than that plus one character for the
project name can't use this convention, and the module says so instead of producing an invalid name.
Among the verified types that is a Windows virtual machine or scale set (15), a cloud service (15),
and the AKS system node pools (12 for Linux, 6 for Windows). Shorter environment and region codes
leave more room.

## Keeping the list current

The list of resource types is a plain Terraform map in [resource_types.tf](resource_types.tf), one
line per type, next to [regions.tf](regions.tf) and [type_codes.tf](type_codes.tf). It and the table
in [docs/resource-types.md](docs/resource-types.md) are generated from Microsoft's two pages:

```sh
python scripts/generate_resource_types.py
terraform test
```

Run it when Microsoft adds resources or changes a limit, and review the diff. The tests then
check the new data.

Regenerating overwrites `resource_types.tf`. To change a rule or add a type for good, use
`custom_resource_types` instead of editing that file, or the change will be lost. The
`supported_resource_types` output shows every type the module knows, including your custom ones.

## Development

Needs Terraform 1.9 or later.

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

The tests run offline. [tests/naming.tftest.hcl](tests/naming.tftest.hcl) covers the behaviour and
error cases, and [tests/all_types.tftest.hcl](tests/all_types.tftest.hcl) builds a name for every
verified type and checks each against its own rules, with both a long and a short project name.
