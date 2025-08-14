MERGE INTO hkr_monitoring.alerts.uc_permission_violations_log AS t  
USING (  
    SELECT  
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
    WHERE ...  
) AS s  
ON t.event_time = s.event_time  
   AND t.granter = s.granter  
   AND t.securable_full_name = s.securable_full_name  
WHEN NOT MATCHED THEN  
  INSERT *  
;  