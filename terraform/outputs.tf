output "debug_sql_query" {
  value = var.debug_output ? local.query_sql : null
}
