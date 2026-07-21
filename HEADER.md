<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Storage Account

Storage accounts (full surface) with secure defaults, plus optional encryption scopes and lifecycle policies.

[![CI](https://github.com/libre-devops/terraform-azurerm-storage-account/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-storage-account/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-storage-account?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-storage-account/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-storage-account)](./LICENSE)

---

## Overview

Storage accounts keyed by name, covering the full `azurerm_storage_account` surface (identity, CMK,
blob/share properties, network rules, routing, SAS policy, immutability, files auth, custom domain) plus
optional per-account **encryption scopes** and a **management (lifecycle) policy**. Secure by default:
**TLS 1.2** minimum, **HTTPS only**, **infrastructure encryption** on, anonymous nested (blob) access and
**cross-tenant replication** off, and a **deny-by-default network rule set** (Azure services bypass; the
public endpoint is reachable only from allow-listed IPs/subnets). Set `public_network_access_enabled =
false` and add a private endpoint for full isolation. Ship logs/metrics via the `diagnostic-settings`
module. The resource group is passed by id.

> The deprecated inline `queue_properties` and `static_website` blocks (removed in azurerm v5.0) are out
> of scope; their dedicated `azurerm_storage_account_queue_properties` / `_static_website` resources are
> data-plane and clash with a deny-by-default network rule set. Configure them separately if needed.

To manage the firewall **outside** this module (with the
[`storage-account-network-rules`](https://registry.terraform.io/modules/libre-devops/storage-account-network-rules/azurerm)
module), set `manage_network_rules = false` on the account: the inline `network_rules` block is omitted
entirely, since Azure allows only one rule set per account and an inline block would fight the
standalone resource with perpetual diffs. An explicit `network_rules = null` does **not** do this
(Terraform replaces a null optional attribute with its default, so the deny block would still render).

## Usage

```hcl
module "storage" {
  source  = "libre-devops/storage-account/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  storage_accounts = {
    "stldouksprd001" = {
      account_replication_type = "ZRS"
      network_rules            = { default_action = "Deny", ip_rules = ["203.0.113.0/24"] }
      blob_properties          = { versioning_enabled = true, delete_retention_policy = { days = 7 } }
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - a single account with the secure defaults.
- [`examples/complete`](./examples/complete) - an account with blob versioning and soft-delete, a
  network allow-list, an encryption scope, and a lifecycle management policy, with its metrics shipped
  to a Log Analytics workspace via the `diagnostic-settings` module.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| AVD-AZU-0057 | Storage accounts (`main.tf`) | No storage analytics logging | Logging is via Azure Monitor diagnostic settings (the `diagnostic-settings` module), not the deprecated legacy analytics logging this check looks for. |
| AVD-AZU-0058 | Storage accounts (`main.tf`) | Not geo-redundant | Replication is a caller cost/resilience choice, not a security control. The module defaults to LRS and accepts all tiers; geo-redundancy is opt-in. |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
