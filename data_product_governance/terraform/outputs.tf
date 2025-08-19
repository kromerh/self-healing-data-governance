output "catalog_grants_grouped" {
  value       = local.catalog_grants_grouped
  description = "Grouped access grants for catalogs"
}

output "schema_grants_grouped" {
  value       = local.schema_grants_grouped
  description = "Grouped access grants for schemas"
}

output "table_grants_grouped" {
  value       = local.table_grants_grouped
  description = "Grouped access grants for tables"
}
