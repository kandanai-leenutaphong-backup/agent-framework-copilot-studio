# Microsoft Agent Framework - Copilot Studio Sample

A Python sample showing how to connect to Microsoft Copilot Studio agents using the Agent Framework. Includes both basic and advanced integration examples.

Made by [iLoveAgent.ai](https://iloveagent.ai)

## Quick Start

```bash
# Install dependencies
uv sync

# Set up Azure app (first time only)
./setup_azure_app.sh

# Run it
uv run main.py
```

## What You Need

- Python 3.10 or higher
- uv package manager
- Azure subscription with Copilot Studio access
- Azure CLI (for the setup script)

## Configuration

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Fill in your values:

- `COPILOTSTUDIOAGENT__ENVIRONMENTID` - Your environment ID (format: `Default-<guid>`)
- `COPILOTSTUDIOAGENT__SCHEMANAME` - Your agent's schema name
- `COPILOTSTUDIOAGENT__AGENTAPPID` - Azure app client ID (set by setup script)
- `COPILOTSTUDIOAGENT__TENANTID` - Your tenant ID (set by setup script)

Find your environment ID in the [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/).

## Examples

### Basic Usage (main.py)

Simple integration using environment variables:

```python
from agent_framework.microsoft import CopilotStudioAgent

agent = CopilotStudioAgent()

# Non-streaming
result = await agent.run("What is AI?")

# Streaming
async for chunk in agent.run_stream("Tell me about Azure"):
    if chunk.text:
        print(chunk.text, end="", flush=True)
```

### Advanced Usage (copilotstudio_explicit.py)

Explicit configuration for more control:

```python
from agent_framework.microsoft import CopilotStudioAgent, acquire_token
from microsoft_agents.copilotstudio.client import ConnectionSettings, CopilotClient, PowerPlatformCloud

token = acquire_token(client_id="...", tenant_id="...")

settings = ConnectionSettings(
    environment_id="Default-...",
    agent_identifier="...",
    cloud=PowerPlatformCloud.PROD
)

client = CopilotClient(settings=settings, token=token)
agent = CopilotStudioAgent(client=client)
```

## Azure Setup

### Automated

The setup script handles everything for you:

```bash
./setup_azure_app.sh
```

Or with a custom app name:

```bash
AZURE_APP_NAME="my-copilot-app" ./setup_azure_app.sh
```

### Manual

If you need to do it manually:

```bash
# 1. Create app
az ad app create \
  --display-name "copilot-studio-agent" \
  --sign-in-audience AzureADMyOrg \
  --public-client-redirect-uris "http://localhost"

# 2. Enable public client flows
az ad app update --id <APP_ID> --set isFallbackPublicClient=true

# 3. Register Power Platform API
az ad sp create --id 8578e004-a5c6-46e7-913e-12f58912df43

# 4. Add permission
az ad app permission add --id <APP_ID> \
  --api 8578e004-a5c6-46e7-913e-12f58912df43 \
  --api-permissions 204440d3-c1d0-4826-b570-99eb6f5e2aeb=Scope

# 5. Grant consent
az ad app permission admin-consent --id <APP_ID>
```

## Troubleshooting

**Authentication fails?**

```bash
rm -f .msal_token_cache.json
uv run main.py
```

**Can't connect to environment?**

- Check your environment ID format: `Default-<guid>` (capital D, with hyphen)
- Make sure your agent is published in Copilot Studio
- Verify you have access in Power Platform Admin Center

**Permission errors?**

```bash
# Create the Power Platform service principal if missing
az ad sp create --id 8578e004-a5c6-46e7-913e-12f58912df43

# Re-grant consent
az ad app permission admin-consent --id <YOUR_APP_ID>
```

## What's Included

- `main.py` - Basic example with streaming and non-streaming
- `copilotstudio_explicit.py` - Advanced configuration example
- `setup_azure_app.sh` - Automated Azure AD setup
- `.env.example` - Configuration template

## Dependencies

- agent-framework-copilotstudio (latest preview: 1.0.0b251120)
- python-dotenv
- aiohttp

## Links

- [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- [Copilot Studio Docs](https://learn.microsoft.com/microsoft-copilot-studio/)
- [Power Platform Admin](https://admin.powerplatform.microsoft.com/)

## About

This sample is maintained by [iLoveAgent.ai](https://iloveagent.ai). We help teams build and deploy AI agents with Microsoft Copilot Studio and Agent Framework.

Need help with your project? Check out [iLoveAgent.ai](https://iloveagent.ai).

## License

MIT License - see LICENSE file for details.
