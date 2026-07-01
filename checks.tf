# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# The module does nothing without at least one storage account.
check "has_storage_accounts" {
  assert {
    condition     = length(var.storage_accounts) > 0
    error_message = "No storage_accounts were supplied, so this module creates nothing."
  }
}

# A deny-by-default network rule set is the secure baseline; warn if one is opened to Allow.
check "network_rules_default_deny" {
  assert {
    condition = alltrue([
      for s in values(var.storage_accounts) : s.network_rules == null ? true : s.network_rules.default_action == "Deny"
    ])
    error_message = "A storage account has network_rules.default_action = Allow, which permits all networks. Prefer Deny with explicit ip_rules / virtual_network_subnet_ids, or a private endpoint."
  }
}
