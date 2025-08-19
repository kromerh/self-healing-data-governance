MERGE INTO hkr_monitoring.alerts.uc_permission_violations_log AS t  
USING (  
    SELECT  
        current_timestamp() AS logged_at,  
        event_time,  
        user_identity.email AS granter,  
        request_params['changes'] AS perm_changes,  
        request_params['securable_type'] AS securable_type,  
        request_params['securable_full_name'] AS securable_full_name,  
        flatten(  
            transform(  
                from_json(request_params['changes'], 'array<struct<principal:string,add:array<string>>>'),  
                x -> x.add  
            )  
        ) AS add_privs  
    FROM system.access.audit  
    WHERE service_name = 'unityCatalog'  
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
                    'MODIFY','SELECT','CREATE_MODEL','ALL_PRIVILEGES','USE_CATALOG',  
                    'USE_SCHEMA','EXECUTE','CREATE_FUNCTION','CREATE_VOLUME',  
                    'READ_VOLUME','WRITE_VOLUME'  
                )  
            )  
        ) > 0  
) AS s  
ON t.event_time = s.event_time  
   AND t.granter = s.granter  
   AND t.securable_full_name = s.securable_full_name  
WHEN NOT MATCHED THEN  
  INSERT (  
      logged_at,  
      event_time,  
      granter,  
      perm_changes,  
      securable_type,  
      securable_full_name,  
      add_privs  
  )  
  VALUES (  
      s.logged_at,  
      s.event_time,  
      s.granter,  
      s.perm_changes,  
      s.securable_type,  
      s.securable_full_name,  
      s.add_privs  
  );  