import requests  
import json  
  
# --- Get secrets ---  
GITHUB_OWNER = dbutils.secrets.get("self-healing-governance", "github-owner")  
GITHUB_REPO = dbutils.secrets.get("self-healing-governance", "github-repo")  
GITHUB_TOKEN = dbutils.secrets.get("self-healing-governance", "github-token")  
EVENT_TYPE = "databricks_alert_triggered"  
  
# --- Run SQL to get violation count ---  
df = spark.sql("""  
    SELECT COUNT(*) AS perm_changes  
    FROM hkr_monitoring.alerts.uc_permission_violations_log  
    WHERE logged_at > (current_timestamp() - INTERVAL 10 MINUTES)  
""")  
  
perm_changes = df.collect()[0]["perm_changes"]  
  
print(f"🔍 Found {perm_changes} privilege changes in last 10 minutes.")  
  
# --- Only trigger GitHub if there are violations ---  
if perm_changes > 0:  
    payload = {  
        "event_type": EVENT_TYPE,  
        "client_payload": {  
            "alert_name": "UC Recent Privilege Grants",  
            "triggered_by": "Databricks Scheduled Job",  
            "extra_info": "Add whatever you like here"  
        }  
    }  
  
    url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/dispatches"  
    headers = {  
        "Accept": "application/vnd.github.v3+json",  
        "Authorization": f"token {GITHUB_TOKEN}"  
    }  
  
    print("🚀 Triggering GitHub Action...")  
    response = requests.post(url, headers=headers, data=json.dumps(payload))  
  
    if response.status_code == 204:  
        print("✅ Successfully triggered GitHub Action.")  
    else:  
        print(f"❌ Failed to trigger GitHub Action: {response.status_code} {response.text}")  
        raise RuntimeError("Failed to trigger GitHub Action")  
else:  
    print("ℹ️ No recent privilege grants detected. No action taken.")
