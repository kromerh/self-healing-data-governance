output "debug_insert_sql" {
  value = var.debug_output ? local.insert_sql : null
}
