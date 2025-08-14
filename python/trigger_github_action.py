import requests  
import json  
  
# Configuration  
GITHUB_OWNER = dbutils.secrets.get("self-healing-governance", "github-owner")
GITHUB_REPO = dbutils.secrets.get("self-healing-governance", "github-repo")
GITHUB_TOKEN = dbutils.secrets.get("self-healing-governance", "github-token")
EVENT_TYPE = "databricks_alert_triggered"  
  
# Optional: include details about the alert  
payload = {  
    "event_type": EVENT_TYPE,  
    "client_payload": {  
        "alert_name": "UC Recent Privilege Grants",  
        "triggered_by": "Databricks Alert",  
        "extra_info": "Add whatever you like here"  
    }  
}  
  
# Make the API request to GitHub  
url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/dispatches"  
headers = {  
    "Accept": "application/vnd.github.v3+json",  
    "Authorization": f"token {GITHUB_TOKEN}"  
}  
  
response = requests.post(url, headers=headers, data=json.dumps(payload))  
  
if response.status_code == 204:  
    print("✅ Successfully triggered GitHub Action.")  
else:  
    print(f"❌ Failed to trigger GitHub Action: {response.status_code} {response.text}")  