variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "account_tier" {
  type        = string
  description = "The account tier of the storage account"
  default     = "Standard"
}

variable "replication_type" {
  type        = string
  description = "The replication type for the storage account"
  default     = "LRS"
}

variable "access_tier" {
  type        = string
  description = "The access tier for the storage account, e.g hot"
}

variable "enable_https_traffic_only" {
  type        = bool
  description = "Whether only HTTPS traffic is allowed"
  default     = true
}

variable "is_hns_enabled" {
  type        = bool
  description = "Whehter HNS is enabled or not, default is false"
  default     = false
}

variable "nfsv3_enabled" {
  type        = bool
  description = "Whether nfsv3 is enabled, default is false"
  default     = "false"
}

variable "min_tls_version" {
  type        = string
  description = "The minimum TLS version for the storage account, default is TLS1_2"
  default     = "TLS1_2"
}

variable "large_file_share_enabled" {
  type        = bool
  description = "Whether large file transfers are enabled for storage account, default is false"
  default     = false
}

variable "network_rules" {
  type        = map(any)
  description = "Are network rules needed? set variable to true"
  default     = {}
}

variable "identity_type" {
  description = "The Managed Service Identity Type of this Virtual Machine."
  type        = string
  default     = ""
}

variable "identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned to the VM."
  type        = list(string)
  default     = []
}
