output "diagnostic_setting_ids" {
  description = "The diagnostic setting ids shipping account metrics to the workspace."
  value       = module.diagnostics.diagnostic_setting_ids
}

output "encryption_scope_ids" {
  description = "The encryption scope ids."
  value       = module.storage.encryption_scope_ids
}

output "management_policy_ids" {
  description = "The lifecycle management policy ids."
  value       = module.storage.management_policy_ids
}

output "storage_account_ids" {
  description = "Map of storage account name to resource id."
  value       = module.storage.ids
}

output "tags" {
  description = "The tags applied to the resources."
  value       = module.tags.tags
}
