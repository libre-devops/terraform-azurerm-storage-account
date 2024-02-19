output "primary_access_keys" {
  description = "The primary access keys of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.primary_access_key }
}

output "primary_blob_connection_strings" {
  description = "The primary connection strings for blob storage of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.primary_blob_connection_string }
}

output "primary_blob_endpoints" {
  description = "The primary blob endpoints of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.primary_blob_endpoint }
}

output "primary_file_endpoints" {
  description = "The primary file endpoints of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.primary_file_endpoint }
}

output "primary_queue_endpoints" {
  description = "The primary queue endpoints of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.primary_queue_endpoint }
}

output "primary_table_endpoints" {
  description = "The primary table endpoints of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.primary_table_endpoint }
}

output "sas_tokens" {
  value = {
    for k, sas in data.azurerm_storage_account_sas.sas : k => sas.sas
  }
  description = "The SAS tokens for the storage accounts."
  sensitive   = true
}

output "secondary_access_keys" {
  description = "The secondary access keys of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.secondary_access_key }
}

output "secondary_table_endpoints" {
  description = "The secondary table endpoints of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.secondary_table_endpoint }
}

output "storage_account_identities" {
  description = "The identities of the Storage Accounts."
  value = {
    for key, value in azurerm_storage_account.sa : key => {
      type         = try(value.identity.0.type, null)
      principal_id = try(value.identity.0.principal_id, null)
      tenant_id    = try(value.identity.0.tenant_id, null)
    }
  }
}

output "storage_account_ids" {
  description = "The IDs of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.id }
}

output "storage_account_locations" {
  description = "The locations of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.location }
}

output "storage_account_names" {
  description = "The names of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.name }
}

output "storage_account_resource_groups" {
  description = "The resource group names of the storage accounts."
  value       = { for sa in azurerm_storage_account.sa : sa.name => sa.resource_group_name }
}
