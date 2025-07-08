# N8N - AI powered workflow

## local testing

```
docker compose \
    -f n8n.local.yaml \
    -f mcp-hub.local.yaml \
    up
```

## Going Live


### Creating a secure passord for MCPHub dashboard

```
htpasswd -bnBC 10 "" YOUR_PASSWORD | tr -d ':\n'
```

### Create a mcp_setting.json file

This file is the core configuration of MCPHub and will be saved as a docker secret as it contains sensitive information, such as API credentials.

```json
{
  "mcpServers": {
    # Add your default MCP server config here
  },
  "users": [
    # Add your default admin user here and other users if needed
    {
      "username": "admin",
      "password": "YOUR_PASSWORD_ENCRYPTED_PASSWORD",
      "isAdmin": true
    }
  ]
}
```