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
  query_sql = file(var.sql_file_path)
  insert_sql = file(var.insert_sql_file_path)
}

resource "databricks_notebook" "trigger_github_action" {
  source = var.databricks_notebook_path
  path   = "${data.databricks_current_user.me.home}/python/trigger_github_action.py"
}

resource "databricks_job" "trigger_github_workflow" {
  name        = "Trigger GitHub Action"
  description = "Runs a notebook that triggers a GitHub Action via repository_dispatch event"

  task {
    task_key = "trigger_github_action"

    notebook_task {
      notebook_path = databricks_notebook.trigger_github_action.path
    }
  }
}

  
resource "databricks_query" "insert_into_violation_log" {  
  warehouse_id = data.databricks_sql_warehouse.sql_endpoint.id  
  display_name = "Insert UC Privilege Grant Violations into Log"  
  query_text   = local.insert_sql  
}  
  
# Schedule this query to run periodically  
resource "databricks_query_schedule" "insert_schedule" {  
  query_id             = databricks_query.insert_into_violation_log.id  
  quartz_cron_expression = "0 0/10 * * * ?"  # every 10 minutes  
  timezone_id          = "Europe/Amsterdam"  
}  


resource "databricks_query" "alert_uc_recent_privilege_grants" {
  warehouse_id = data.databricks_sql_warehouse.sql_endpoint.id
  display_name = "alert_uc_recent_privilege_grants"
  query_text   = local.query_sql
}

resource "databricks_alert_v2" "basic_alert" {
  display_name     = "UC Recent Privilege Grants"
  query_text       = databricks_query.alert_uc_recent_privilege_grants.query_text
  warehouse_id     = data.databricks_sql_warehouse.sql_endpoint.id
  parent_path      = "/Workspace/Users/heiko.kromer@ms.d-one.ai"
  run_as_user_name = "heiko.kromer@ms.d-one.ai"

  evaluation = {
    source = {
      name        = "perm_changes"
      display     = "Permission Changes"
      aggregation = "COUNT"
    }
    comparison_operator = "GREATER_THAN"
    threshold = {
      value = {
        double_value = 1
      }
    }
    empty_result_state = "OK"

    notification = {
      subscriptions = [
        {
          user_email  = "heiko.kromer@ms.d-one.ai",
          workflow_id = databricks_job.trigger_github_workflow.id
        }
      ]
      retrigger_seconds = 10
      notify_on_ok      = true
    }

  }

  schedule = {
    quartz_cron_schedule = "0 0/10 * * * ?" # Every Day Every 10 minutes
    timezone_id          = "Europe/Amsterdam"
    pause_status         = "UNPAUSED"
  }
}
