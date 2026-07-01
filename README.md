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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_encryption_scope.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_encryption_scope) | resource |
| [azurerm_storage_management_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for the storage accounts. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group to create the storage accounts in. The name and subscription are parsed from it (pass the rg module's ids output). | `string` | n/a | yes |
| <a name="input_storage_accounts"></a> [storage\_accounts](#input\_storage\_accounts) | Storage accounts to create, keyed by account name. Exhaustive azurerm\_storage\_account surface plus<br/>optional per-account encryption\_scopes and a management\_policy (lifecycle rules).<br/><br/>Secure defaults: min\_tls\_version TLS1\_2, HTTPS only, infrastructure encryption on, anonymous nested<br/>(blob) access off, cross-tenant replication off, and a deny-by-default network\_rules set with Azure<br/>services allowed to bypass (so the public endpoint is reachable only from allow-listed IPs/subnets;<br/>add ip\_rules / virtual\_network\_subnet\_ids or a private endpoint, or set public\_network\_access\_enabled<br/>= false, for tighter isolation). Ship logs via the diagnostic-settings module rather than legacy<br/>storage analytics logging.<br/><br/>NOTE: the inline queue\_properties and static\_website blocks are deprecated on azurerm\_storage\_account<br/>(removed in provider v5.0), and their replacements (azurerm\_storage\_account\_queue\_properties /<br/>azurerm\_storage\_account\_static\_website) are data-plane resources that clash with a deny-by-default<br/>network rule set, so they are intentionally out of scope here; configure them separately when needed. | <pre>map(object({<br/>    account_tier             = optional(string, "Standard")<br/>    account_replication_type = optional(string, "LRS")<br/>    account_kind             = optional(string, "StorageV2")<br/>    access_tier              = optional(string)<br/><br/>    min_tls_version                   = optional(string, "TLS1_2")<br/>    https_traffic_only_enabled        = optional(bool, true)<br/>    infrastructure_encryption_enabled = optional(bool, true)<br/>    allow_nested_items_to_be_public   = optional(bool, false)<br/>    cross_tenant_replication_enabled  = optional(bool, false)<br/>    public_network_access_enabled     = optional(bool, true)<br/>    shared_access_key_enabled         = optional(bool, true)<br/>    default_to_oauth_authentication   = optional(bool, false)<br/>    allowed_copy_scope                = optional(string)<br/>    is_hns_enabled                    = optional(bool)<br/>    nfsv3_enabled                     = optional(bool)<br/>    sftp_enabled                      = optional(bool)<br/>    large_file_share_enabled          = optional(bool)<br/>    local_user_enabled                = optional(bool)<br/>    queue_encryption_key_type         = optional(string)<br/>    table_encryption_key_type         = optional(string)<br/>    dns_endpoint_type                 = optional(string)<br/>    edge_zone                         = optional(string)<br/>    provisioned_billing_model_version = optional(string)<br/><br/>    identity = optional(object({<br/>      type         = string<br/>      identity_ids = optional(list(string), [])<br/>    }))<br/><br/>    customer_managed_key = optional(object({<br/>      user_assigned_identity_id = string<br/>      key_vault_key_id          = optional(string)<br/>      managed_hsm_key_id        = optional(string)<br/>    }))<br/><br/>    network_rules = optional(object({<br/>      default_action             = optional(string, "Deny")<br/>      bypass                     = optional(set(string), ["AzureServices"])<br/>      ip_rules                   = optional(list(string), [])<br/>      virtual_network_subnet_ids = optional(list(string), [])<br/>      private_link_access = optional(list(object({<br/>        endpoint_resource_id = string<br/>        endpoint_tenant_id   = optional(string)<br/>      })), [])<br/>    }), {})<br/><br/>    blob_properties = optional(object({<br/>      versioning_enabled            = optional(bool)<br/>      change_feed_enabled           = optional(bool)<br/>      change_feed_retention_in_days = optional(number)<br/>      default_service_version       = optional(string)<br/>      last_access_time_enabled      = optional(bool)<br/>      delete_retention_policy = optional(object({<br/>        days                     = optional(number)<br/>        permanent_delete_enabled = optional(bool)<br/>      }))<br/>      container_delete_retention_policy = optional(object({<br/>        days = optional(number)<br/>      }))<br/>      restore_policy = optional(object({<br/>        days = number<br/>      }))<br/>      cors_rules = optional(list(object({<br/>        allowed_headers    = list(string)<br/>        allowed_methods    = list(string)<br/>        allowed_origins    = list(string)<br/>        exposed_headers    = list(string)<br/>        max_age_in_seconds = number<br/>      })), [])<br/>    }))<br/><br/>    share_properties = optional(object({<br/>      retention_policy = optional(object({<br/>        days = optional(number)<br/>      }))<br/>      smb = optional(object({<br/>        versions                        = optional(set(string))<br/>        authentication_types            = optional(set(string))<br/>        kerberos_ticket_encryption_type = optional(set(string))<br/>        channel_encryption_type         = optional(set(string))<br/>        multichannel_enabled            = optional(bool)<br/>      }))<br/>      cors_rules = optional(list(object({<br/>        allowed_headers    = list(string)<br/>        allowed_methods    = list(string)<br/>        allowed_origins    = list(string)<br/>        exposed_headers    = list(string)<br/>        max_age_in_seconds = number<br/>      })), [])<br/>    }))<br/><br/>    azure_files_authentication = optional(object({<br/>      directory_type                 = string<br/>      default_share_level_permission = optional(string)<br/>      active_directory = optional(object({<br/>        domain_name         = string<br/>        domain_guid         = string<br/>        domain_sid          = optional(string)<br/>        forest_name         = optional(string)<br/>        netbios_domain_name = optional(string)<br/>        storage_sid         = optional(string)<br/>      }))<br/>    }))<br/><br/>    routing = optional(object({<br/>      choice                      = optional(string)<br/>      publish_internet_endpoints  = optional(bool)<br/>      publish_microsoft_endpoints = optional(bool)<br/>    }))<br/><br/>    sas_policy = optional(object({<br/>      expiration_period = string<br/>      expiration_action = optional(string)<br/>    }))<br/><br/>    custom_domain = optional(object({<br/>      name          = string<br/>      use_subdomain = optional(bool)<br/>    }))<br/><br/>    immutability_policy = optional(object({<br/>      state                         = string<br/>      period_since_creation_in_days = number<br/>      allow_protected_append_writes = bool<br/>    }))<br/><br/>    encryption_scopes = optional(map(object({<br/>      source                             = string<br/>      key_vault_key_id                   = optional(string)<br/>      infrastructure_encryption_required = optional(bool)<br/>    })), {})<br/><br/>    management_policy = optional(object({<br/>      rules = list(object({<br/>        name    = string<br/>        enabled = optional(bool, true)<br/>        filters = object({<br/>          blob_types   = list(string)<br/>          prefix_match = optional(list(string), [])<br/>          match_blob_index_tags = optional(list(object({<br/>            name      = string<br/>            value     = string<br/>            operation = optional(string, "==")<br/>          })), [])<br/>        })<br/>        actions = object({<br/>          base_blob = optional(object({<br/>            tier_to_cool_after_days_since_modification_greater_than        = optional(number)<br/>            tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)<br/>            tier_to_cool_after_days_since_creation_greater_than            = optional(number)<br/>            tier_to_cold_after_days_since_modification_greater_than        = optional(number)<br/>            tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)<br/>            tier_to_cold_after_days_since_creation_greater_than            = optional(number)<br/>            tier_to_archive_after_days_since_modification_greater_than     = optional(number)<br/>            tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)<br/>            tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br/>            tier_to_archive_after_days_since_creation_greater_than         = optional(number)<br/>            delete_after_days_since_modification_greater_than              = optional(number)<br/>            delete_after_days_since_last_access_time_greater_than          = optional(number)<br/>            delete_after_days_since_creation_greater_than                  = optional(number)<br/>            auto_tier_to_hot_from_cool_enabled                             = optional(bool)<br/>          }))<br/>          snapshot = optional(object({<br/>            change_tier_to_cool_after_days_since_creation                  = optional(number)<br/>            change_tier_to_archive_after_days_since_creation               = optional(number)<br/>            tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br/>            tier_to_cold_after_days_since_creation_greater_than            = optional(number)<br/>            delete_after_days_since_creation_greater_than                  = optional(number)<br/>          }))<br/>          version = optional(object({<br/>            change_tier_to_cool_after_days_since_creation                  = optional(number)<br/>            change_tier_to_archive_after_days_since_creation               = optional(number)<br/>            tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)<br/>            tier_to_cold_after_days_since_creation_greater_than            = optional(number)<br/>            delete_after_days_since_creation                               = optional(number)<br/>          }))<br/>        })<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the storage accounts. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_encryption_scope_ids"></a> [encryption\_scope\_ids](#output\_encryption\_scope\_ids) | Map of "<account>\|<scope>" to the encryption scope id. |
| <a name="output_identity_principal_ids"></a> [identity\_principal\_ids](#output\_identity\_principal\_ids) | Map of account name to its identity principal id (only accounts with an identity). |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of storage account name to its resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of storage account name to a { name, id } object, for passing where both are needed together. |
| <a name="output_management_policy_ids"></a> [management\_policy\_ids](#output\_management\_policy\_ids) | Map of account name to its management (lifecycle) policy id. |
| <a name="output_names"></a> [names](#output\_names) | The storage account names. |
| <a name="output_primary_access_keys"></a> [primary\_access\_keys](#output\_primary\_access\_keys) | Map of account name to its primary access key. |
| <a name="output_primary_blob_endpoints"></a> [primary\_blob\_endpoints](#output\_primary\_blob\_endpoints) | Map of account name to its primary blob endpoint. |
| <a name="output_primary_connection_strings"></a> [primary\_connection\_strings](#output\_primary\_connection\_strings) | Map of account name to its primary connection string. |
| <a name="output_primary_web_endpoints"></a> [primary\_web\_endpoints](#output\_primary\_web\_endpoints) | Map of account name to its primary static-website endpoint. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from resource\_group\_id. |
| <a name="output_secondary_access_keys"></a> [secondary\_access\_keys](#output\_secondary\_access\_keys) | Map of account name to its secondary access key. |
| <a name="output_storage_accounts"></a> [storage\_accounts](#output\_storage\_accounts) | Map of account name to key attributes (id, name, tier, replication, kind, and blob/dfs/web endpoints). |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from resource\_group\_id. |
| <a name="output_tags"></a> [tags](#output\_tags) | The tags applied to the storage accounts. |
<!-- END_TF_DOCS -->
