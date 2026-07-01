locals {
  rg                  = provider::azurerm::parse_resource_id(var.resource_group_id)
  resource_group_name = local.rg.resource_group_name

  # Flatten per-account encryption scopes to one map keyed "<account>|<scope>".
  encryption_scopes = merge([
    for sa_name, sa in var.storage_accounts : {
      for scope_name, scope in sa.encryption_scopes : "${sa_name}|${scope_name}" => {
        account_name                       = sa_name
        name                               = scope_name
        source                             = scope.source
        key_vault_key_id                   = scope.key_vault_key_id
        infrastructure_encryption_required = scope.infrastructure_encryption_required
      }
    }
  ]...)

  # Accounts that declare a management (lifecycle) policy, keyed by account name.
  management_policies = {
    for sa_name, sa in var.storage_accounts : sa_name => sa.management_policy if sa.management_policy != null
  }
}
