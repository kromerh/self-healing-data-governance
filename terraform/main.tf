terraform {
  required_version = "= 1.12.2"
  backend "azurerm" {}
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.85.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.36.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.provider_azurerm.subscription_id
  tenant_id       = var.provider_azurerm.tenant_id
  features {}
}

provider "databricks" {
  host = var.provider_databricks_workspace.host
}

data "databricks_sql_warehouse" "sql_endpoint" {
  name = var.databricks_sql_warehouse_name
}

data "databricks_current_user" "me" {
}

locals {
  insert_sql = file(var.insert_sql_file_path)
}

resource "databricks_notebook" "check_and_trigger_github" {
  source = var.databricks_notebook_path
  path   = "${data.databricks_current_user.me.home}/python/check_and_trigger_github.py"
}

resource "databricks_query" "insert_into_violation_log" {
  warehouse_id = data.databricks_sql_warehouse.sql_endpoint.id
  display_name = "Insert UC Privilege Grant Violations into Log"
  query_text   = local.insert_sql
}

resource "databricks_job" "uc_permission_monitor" {
  name        = "UC Permission Change Monitor"
  description = "Checks for UC privilege grants and triggers GitHub workflow if found"

  schedule {
    quartz_cron_expression = "0 0/10 * * * ?" # every 10 minutes  
    timezone_id            = "Europe/Amsterdam"
    pause_status           = "UNPAUSED"
  }

  # Task 1: Insert violations into log  
  task {
    task_key = "insert_into_log"
    sql_task {
      warehouse_id = data.databricks_sql_warehouse.sql_endpoint.id
      query {
        query_id = databricks_query.insert_into_violation_log.id
      }
    }
  }

  # Task 2: Check violations and trigger GitHub
  task {
    task_key = "check_and_trigger"
    depends_on {
      task_key = "insert_into_log"
    }
    notebook_task {
      notebook_path = databricks_notebook.check_and_trigger_github.path
    }
  }
}
