<!--
Keep the headings as they are: the semantic versioning check reads them.
Text in comments like this one is ignored.
-->

## What

<!-- What does this change? One or two sentences a reviewer can read before opening the diff. -->

## Why

<!-- Why is it needed? The problem it solves, and a link to the ticket or issue. -->

## Version bump

<!-- Tick exactly one. The release is made from this when the pull request merges. -->

- [ ] **Major**: breaking change. Callers must change their code or their state
- [ ] **Minor**: new backwards-compatible feature
- [ ] **Patch**: backwards-compatible fix
- [ ] **None**: no release (docs, tests, or CI only)

## Breaking changes and migration

<!-- Required for Major. Say what breaks and what callers must change. Write N/A otherwise. -->

## How it was tested

<!-- Commands you ran and what you saw. Not needed for None. -->

## Standards

<!-- Tick every item. If one doesn't apply, tick it and write N/A and the reason after it. -->

- [ ] Every input and output has a description and a type
- [ ] Nothing is hardcoded that callers may need to change
- [ ] Changes to resource types, regions, or type codes keep the tests passing, and generated files (`resource_types.tf`, `docs/resource-types.md`) come from `scripts/generate_resource_types.py`
- [ ] No secrets, keys, or tokens in code, examples, or tests
- [ ] Terraform version constraint is set and still correct
- [ ] README and examples are up to date
- [ ] `terraform fmt`, `terraform validate`, and `terraform test` pass
- [ ] The change is backwards compatible, or the bump above is Major

