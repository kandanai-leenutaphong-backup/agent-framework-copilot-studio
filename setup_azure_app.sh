#!/bin/bash

# Script to create Azure AD App Registration for Copilot Studio Agent

# Default app name (can be overridden with environment variable)
APP_NAME="${AZURE_APP_NAME:-copilot-studio-agent}"
REDIRECT_URI="http://localhost"

echo "=============================================="
echo "Azure AD App Registration Setup"
echo "=============================================="
echo ""
echo "App name: $APP_NAME"
echo "(Set AZURE_APP_NAME environment variable to use a different name)"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed."
    echo "Please install it from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Login to Azure
echo "Logging in to Azure..."
az login

if [ $? -ne 0 ]; then
    echo "Error: Failed to login to Azure"
    exit 1
fi

echo ""
echo "Creating app registration: $APP_NAME"
echo ""

# Check if app already exists
EXISTING_APP=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null)

if [ -n "$EXISTING_APP" ]; then
    echo "App registration '$APP_NAME' already exists with ID: $EXISTING_APP"
    echo "Do you want to use this existing app? (y/n)"
    read -r USE_EXISTING
    
    if [ "$USE_EXISTING" != "y" ]; then
        echo "Please delete the existing app or choose a different name."
        exit 1
    fi
    
    APP_ID=$EXISTING_APP
else
    # Create the app registration
    APP_ID=$(az ad app create \
        --display-name "$APP_NAME" \
        --sign-in-audience AzureADMyOrg \
        --public-client-redirect-uris "$REDIRECT_URI" \
        --query appId -o tsv)

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create app registration"
        exit 1
    fi

    echo "✓ App registration created successfully"
    echo "  App ID: $APP_ID"
fi

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "=============================================="
echo "App Registration Details"
echo "=============================================="
echo "App Name:    $APP_NAME"
echo "Client ID:   $APP_ID"
echo "Tenant ID:   $TENANT_ID"
echo "Redirect URI: $REDIRECT_URI"
echo ""

# Get the object ID for the app
APP_OBJECT_ID=$(az ad app show --id "$APP_ID" --query id -o tsv)

# Enable public client flows
echo "Enabling public client flows..."
az ad app update --id "$APP_ID" --set publicClient.redirectUris="[\"$REDIRECT_URI\"]" \
    isFallbackPublicClient=true

echo "✓ Public client flows enabled"
echo ""

# Create Power Platform API service principal if it doesn't exist
echo "Ensuring Power Platform API service principal exists..."
POWERPLATFORM_API_ID="8578e004-a5c6-46e7-913e-12f58912df43"
COPILOT_INVOKE_SCOPE_ID="204440d3-c1d0-4826-b570-99eb6f5e2aeb"

# Check if service principal exists, create if not
SP_EXISTS=$(az ad sp show --id "$POWERPLATFORM_API_ID" --query appId -o tsv 2>/dev/null)
if [ -z "$SP_EXISTS" ]; then
    echo "Creating Power Platform API service principal..."
    az ad sp create --id "$POWERPLATFORM_API_ID" > /dev/null 2>&1
    echo "✓ Power Platform API service principal created"
else
    echo "✓ Power Platform API service principal already exists"
fi

# Add Power Platform API permissions
echo "Adding CopilotStudio.Copilots.Invoke permission..."

az ad app permission add \
    --id "$APP_ID" \
    --api "$POWERPLATFORM_API_ID" \
    --api-permissions "$COPILOT_INVOKE_SCOPE_ID=Scope"

if [ $? -eq 0 ]; then
    echo "✓ CopilotStudio.Copilots.Invoke permission added"
    echo ""
    # Try to grant admin consent automatically
    echo "Granting admin consent..."
    if az ad app permission admin-consent --id "$APP_ID" 2>/dev/null; then
        echo "✓ Admin consent granted successfully"
    else
        echo "⚠️  Admin consent requires manual approval."
        echo "   Please grant consent in the Azure Portal:"
        echo "   https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/$APP_ID"
    fi
else
    echo "⚠️  Failed to add permissions automatically."
    echo "   Please add Power Platform API permissions manually in the Azure Portal."
fi

echo ""
echo "=============================================="
echo "Next Steps"
echo "=============================================="
echo ""
echo "1. Update your .env file with the following values:"
echo ""
echo "   COPILOTSTUDIOAGENT__AGENTAPPID=$APP_ID"
echo "   COPILOTSTUDIOAGENT__TENANTID=$TENANT_ID"
echo ""
echo "2. If needed, grant admin consent for API permissions:"
echo "   https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/$APP_ID"
echo ""
echo "3. Run your application:"
echo "   uv run main.py"
echo ""

# Ask if user wants to update .env file automatically
echo "Would you like to update the .env file automatically? (y/n)"
read -r UPDATE_ENV

if [ "$UPDATE_ENV" = "y" ]; then
    if [ -f .env ]; then
        # Update existing .env file
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/COPILOTSTUDIOAGENT__AGENTAPPID=.*/COPILOTSTUDIOAGENT__AGENTAPPID=$APP_ID/" .env
            sed -i '' "s/COPILOTSTUDIOAGENT__TENANTID=.*/COPILOTSTUDIOAGENT__TENANTID=$TENANT_ID/" .env
        else
            # Linux
            sed -i "s/COPILOTSTUDIOAGENT__AGENTAPPID=.*/COPILOTSTUDIOAGENT__AGENTAPPID=$APP_ID/" .env
            sed -i "s/COPILOTSTUDIOAGENT__TENANTID=.*/COPILOTSTUDIOAGENT__TENANTID=$TENANT_ID/" .env
        fi
        echo "✓ .env file updated successfully"
    else
        echo "Error: .env file not found. Please copy .env.example to .env first."
    fi
fi

echo ""
echo "Setup complete!"
