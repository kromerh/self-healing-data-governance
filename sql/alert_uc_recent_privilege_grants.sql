SELECT
  event_time,
  user_identity.email as granter,
  request_params['changes'] as perm_changes,
  request_params['securable_type'] as securable_type,
  request_params['securable_full_name'] as securable_full_name,
  flatten(
    transform(
      from_json(request_params['changes'], 'array<struct<principal:string,add:array<string>>>'),
      x -> x.add
    )
  ) as add_privs
FROM
  system.access.audit
WHERE
  service_name = 'unityCatalog'
  AND action_name = 'updatePermissions'
  AND lower(request_params['securable_type']) IN ('catalog', 'schema', 'table', 'view')
  AND event_time > (current_timestamp() - INTERVAL 70 MINUTES)
  AND response['status_code'] = 200
  AND size(
    array_intersect(
      flatten(
        transform(
          from_json(request_params['changes'], 'array<struct<principal:string,add:array<string>>>'),
          x -> x.add
        )
      ),
      array(
        'MODIFY',
        'SELECT',
        'CREATE_MODEL',
        'ALL_PRIVILEGES',
        'USE_CATALOG',
        'USE_SCHEMA',
        'EXECUTE',
        'CREATE_FUNCTION',
        'CREATE_VOLUME',
        'READ_VOLUME',
        'WRITE_VOLUME'
      )
    )
  ) > 0
ORDER BY
  event_time DESC