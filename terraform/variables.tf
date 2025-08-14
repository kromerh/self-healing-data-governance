variable "provider_azurerm" {
  description = "AzureRM provider config"
  type = object({
    subscription_id = string
    tenant_id       = string
  })
}

variable "provider_databricks_workspace" {
  description = "Databricks workspace provider config"
  type = object({
    host = string
  })
}

variable "databricks_sql_warehouse_name" {
  description = "Name of the Databricks SQL warehouse"
  type        = string
}

variable "debug_output" {
  description = "Whether to output the SQL query text for debugging"
  type        = bool
  default     = false
}

variable "databricks_notebook_path" {
  description = "Path to the Databricks notebook"
  type        = string

}

variable "insert_sql_file_path" {
  description = "Path to the SQL file containing the INSERT statement"
  type        = string
}
