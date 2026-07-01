output "primary_blob_endpoints" {
  description = "Map of storage account name to primary blob endpoint."
  value       = module.storage.primary_blob_endpoints
}

output "storage_account_ids" {
  description = "Map of storage account name to resource id."
  value       = module.storage.ids
}
