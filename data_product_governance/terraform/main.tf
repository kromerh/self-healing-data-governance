terraform {
  required_version = "= 1.12.2"

  backend "azurerm" {}

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.85.0"
    }
  }
}

provider "databricks" {
  host = var.databricks_workspace_url
}

locals {
  access_config = jsondecode(file(".../access_config.json"))

  all_grants = flatten([
    for role_name, role_data in local.access_config : [
      for acl in role_data.access_control_list : {
        principal   = role_name
        object_type = lower(acl.object_type)
        object_name = acl.object_name
        privileges  = acl.access_rights
      }
    ]
  ])

  catalog_grants_grouped = {
    for k, v in {
      for g in local.all_grants :
      "${g.object_type}:${g.object_name}" => g...
      if g.object_type == "catalog"
    } :
    k => {
      object_name = v[0].object_name
      grants = [
        for g in v : {
          principal  = g.principal
          privileges = g.privileges
        }
      ]
    }
  }

  schema_grants_grouped = {
    for k, v in {
      for g in local.all_grants :
      "${g.object_type}:${g.object_name}" => g...
      if g.object_type == "schema"
    } :
    k => {
      object_name = v[0].object_name
      grants = [
        for g in v : {
          principal  = g.principal
          privileges = g.privileges
        }
      ]
    }
  }

  table_grants_grouped = {
    for k, v in {
      for g in local.all_grants :
      "${g.object_type}:${g.object_name}" => g...
      if g.object_type == "table"
    } :
    k => {
      object_name = v[0].object_name
      grants = [
        for g in v : {
          principal  = g.principal
          privileges = g.privileges
        }
      ]
    }
  }
}

resource "databricks_grants" "catalogs" {
  for_each = local.catalog_grants_grouped

  catalog = each.value.object_name

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

resource "databricks_grants" "schemas" {
  for_each = local.schema_grants_grouped

  schema = each.value.object_name

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

resource "databricks_grants" "tables" {
  for_each = local.table_grants_grouped

  table = each.value.object_name

  dynamic "grant" {
    for_each = each.value.grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
