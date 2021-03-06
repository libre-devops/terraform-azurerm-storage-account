```hcl
module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-build" // rg-ldo-euw-dev-build
  location = local.location                                            // compares var.loc with the var.regions var to match a long-hand name, in this case, "euw", so "westeurope"
  tags     = local.tags

  #  lock_level = "CanNotDelete" // Do not set this value to skip lock
}

data "http" "user_ip" {
  url = "https://ipv4.icanhazip.com" // If running locally, running this block will fetch your outbound public IP of your home/office/ISP/VPN and add it.  It will add the hosted agent etc if running from Microsoft/GitLab
}

module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name // rg-ldo-euw-dev-build
  location = module.rg.rg_location
  tags     = local.tags

  vnet_name     = "vnet-${var.short}-${var.loc}-${terraform.workspace}-01" // vnet-ldo-euw-dev-01
  vnet_location = module.network.vnet_location

  address_space   = ["10.0.0.0/16"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names    = ["sn1-${module.network.vnet_name}", "sn2-${module.network.vnet_name}", "sn3-${module.network.vnet_name}"] //sn1-vnet-ldo-euw-dev-01
  subnet_service_endpoints = {
    "sn1-${module.network.vnet_name}" = ["Microsoft.Storage"] // Adds extra subnet endpoints to sn1-vnet-ldo-euw-dev-01
    "sn2-${module.network.vnet_name}" = ["Microsoft.Storage", "Microsoft.Sql"], // Adds extra subnet endpoints to sn2-vnet-ldo-euw-dev-01
    "sn3-${module.network.vnet_name}" = ["Microsoft.AzureActiveDirectory"] // Adds extra subnet endpoints to sn3-vnet-ldo-euw-dev-01
  }
}

module "sa" {
  source = "registry.terraform.io/libre-devops/storage-account/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  storage_account_name = "st${var.short}${var.loc}${terraform.workspace}01"
  access_tier          = "Hot"
  identity_type        = "SystemAssigned"

  storage_account_properties = {

    // Set this block to enable network rules
    network_rules = {
      default_action = "Deny"
      bypass         = ["AzureServices", "Metrics", "Logging"]
      ip_rules       = [chomp(data.http.user_ip.body)]
      subnet_ids     = [element(values(module.network.subnets_ids), 0)]
    }

    blob_properties = {
      versioning_enabled       = false
      change_feed_enabled      = false
      default_service_version  = "2020-06-12"
      last_access_time_enabled = false

      deletion_retention_policies = {
        days = 10
      }

      container_delete_retention_policy = {
        days = 10
      }
    }

    routing = {
      publish_internet_endpoints  = false
      publish_microsoft_endpoints = true
      choice                      = "MicrosoftRouting"
    }
  }
}
```

For a full example build, check out the [Libre DevOps Website](https://www.libredevops.org/quickstart/utils/terraform/using-lbdo-tf-modules-example.html)

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_storage_account.sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tier"></a> [access\_tier](#input\_access\_tier) | The access tier for the storage account, e.g hot | `string` | n/a | yes |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | The account tier of the storage account | `string` | `"Standard"` | no |
| <a name="input_allow_nested_items_to_be_public"></a> [allow\_nested\_items\_to\_be\_public](#input\_allow\_nested\_items\_to\_be\_public) | Whether nested blobs can be set to public from a private top level container | `bool` | `false` | no |
| <a name="input_container_delete_retention_policy"></a> [container\_delete\_retention\_policy](#input\_container\_delete\_retention\_policy) | Are container delete retention policies needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_custom_domain"></a> [custom\_domain](#input\_custom\_domain) | Are customs domain needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key) | Are customer managed needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_delete_retention_policy"></a> [delete\_retention\_policy](#input\_delete\_retention\_policy) | Are delete retention policies needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_enable_https_traffic_only"></a> [enable\_https\_traffic\_only](#input\_enable\_https\_traffic\_only) | Whether only HTTPS traffic is allowed | `bool` | `true` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Specifies a list of user managed identity ids to be assigned to the VM. | `list(string)` | `[]` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | The Managed Service Identity Type of this Virtual Machine. | `string` | `""` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | Whether infrastructure encryption is enabled, default is false | `bool` | `false` | no |
| <a name="input_is_hns_enabled"></a> [is\_hns\_enabled](#input\_is\_hns\_enabled) | Whehter HNS is enabled or not, default is false | `bool` | `false` | no |
| <a name="input_large_file_share_enabled"></a> [large\_file\_share\_enabled](#input\_large\_file\_share\_enabled) | Whether large file transfers are enabled for storage account, default is false | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | The minimum TLS version for the storage account, default is TLS1\_2 | `string` | `"TLS1_2"` | no |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | Are network rules needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_nfsv3_enabled"></a> [nfsv3\_enabled](#input\_nfsv3\_enabled) | Whether nfsv3 is enabled, default is false | `bool` | `"false"` | no |
| <a name="input_queue_encryption_key_type"></a> [queue\_encryption\_key\_type](#input\_queue\_encryption\_key\_type) | The type of queue encryption key, default is Service | `string` | `"Service"` | no |
| <a name="input_replication_type"></a> [replication\_type](#input\_replication\_type) | The replication type for the storage account | `string` | `"LRS"` | no |
| <a name="input_retention_policy"></a> [retention\_policy](#input\_retention\_policy) | Are retention policy settings needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_share_properties"></a> [share\_properties](#input\_share\_properties) | Are share properties settings needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_shared_access_keys_enabled"></a> [shared\_access\_keys\_enabled](#input\_shared\_access\_keys\_enabled) | Whether shared access keys a.k.a storage keys are enabled | `bool` | `true` | no |
| <a name="input_smb"></a> [smb](#input\_smb) | Are smb settings needed? set variable to with a non empty value to use | `map(any)` | `{}` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | The name of the storage account | `string` | n/a | yes |
| <a name="input_storage_account_properties"></a> [storage\_account\_properties](#input\_storage\_account\_properties) | Variable used my module to export dynamic block values | `any` | n/a | yes |
| <a name="input_table_encryption_key_type"></a> [table\_encryption\_key\_type](#input\_table\_encryption\_key\_type) | The type of table encryption key, default is Service | `string` | `"Service"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | <pre>{<br>  "source": "terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sa_id"></a> [sa\_id](#output\_sa\_id) | The ID of the storage account |
| <a name="output_sa_name"></a> [sa\_name](#output\_sa\_name) | The name of the storage account |
| <a name="output_sa_primary_access_key"></a> [sa\_primary\_access\_key](#output\_sa\_primary\_access\_key) | The primary access key of the storage account |
| <a name="output_sa_primary_blob_endpoint"></a> [sa\_primary\_blob\_endpoint](#output\_sa\_primary\_blob\_endpoint) | The primary blob endpoint of the storage account |
| <a name="output_sa_primary_connection_string"></a> [sa\_primary\_connection\_string](#output\_sa\_primary\_connection\_string) | The primary blob connection string of the storage account |
| <a name="output_sa_secondary_access_key"></a> [sa\_secondary\_access\_key](#output\_sa\_secondary\_access\_key) | The secondary access key of the storage account |
