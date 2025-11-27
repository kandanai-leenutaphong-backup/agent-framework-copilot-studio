# Copyright (c) Microsoft. All rights reserved.

import asyncio
import os
from dotenv import load_dotenv
from agent_framework.microsoft import CopilotStudioAgent, acquire_token
from microsoft_agents.copilotstudio.client import AgentType, ConnectionSettings, CopilotClient, PowerPlatformCloud

"""
Copilot Studio Agent with Explicit Settings Example

This sample demonstrates explicit configuration of CopilotStudioAgent with manual
token management and custom ConnectionSettings for production environments.
"""

# Load environment variables from .env file
load_dotenv()


async def example_with_connection_settings() -> None:
    """Example using explicit ConnectionSettings and CopilotClient."""
    print("=== Copilot Studio Agent with Connection Settings ===")

    # Configuration from environment variables
    environment_id = os.environ["COPILOTSTUDIOAGENT__ENVIRONMENTID"]
    agent_identifier = os.environ["COPILOTSTUDIOAGENT__SCHEMANAME"]
    client_id = os.environ["COPILOTSTUDIOAGENT__AGENTAPPID"]
    tenant_id = os.environ["COPILOTSTUDIOAGENT__TENANTID"]

    # Acquire token using the acquire_token function
    token = acquire_token(
        client_id=client_id,
        tenant_id=tenant_id,
    )

    # Create connection settings
    settings = ConnectionSettings(
        environment_id=environment_id,
        agent_identifier=agent_identifier,
        cloud=PowerPlatformCloud.PROD,  
        copilot_agent_type=AgentType.PUBLISHED,  
        custom_power_platform_cloud=None, 
    )

    # Create CopilotClient with explicit settings
    client = CopilotClient(settings=settings, token=token)

    # Create agent with explicit client
    agent = CopilotStudioAgent(client=client)

    # Run a simple query
    query = "What is the capital of Italy?"
    print(f"User: {query}")
    result = await agent.run(query)
    print(f"Agent: {result}")


async def example_with_explicit_parameters() -> None:
    """Example using CopilotStudioAgent with all parameters explicitly provided."""
    print("\n=== Copilot Studio Agent with All Explicit Parameters ===")

    # Configuration from environment variables
    environment_id = os.environ["COPILOTSTUDIOAGENT__ENVIRONMENTID"]
    agent_identifier = os.environ["COPILOTSTUDIOAGENT__SCHEMANAME"]
    client_id = os.environ["COPILOTSTUDIOAGENT__AGENTAPPID"]
    tenant_id = os.environ["COPILOTSTUDIOAGENT__TENANTID"]

    # Create agent with all parameters explicitly
    agent = CopilotStudioAgent(
        environment_id=environment_id,
        agent_identifier=agent_identifier,
        client_id=client_id,
        tenant_id=tenant_id,
        cloud=PowerPlatformCloud.PROD,
        agent_type=AgentType.PUBLISHED,
    )

    # Run a simple query
    query = "What is the capital of Japan?"
    print(f"User: {query}")
    result = await agent.run(query)
    print(f"Agent: {result}")


async def main() -> None:
    # Check if environment variables are set
    required_vars = [
        "COPILOTSTUDIOAGENT__ENVIRONMENTID",
        "COPILOTSTUDIOAGENT__SCHEMANAME",
        "COPILOTSTUDIOAGENT__AGENTAPPID",
        "COPILOTSTUDIOAGENT__TENANTID",
    ]
    
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print("Error: Missing required environment variables:")
        for var in missing_vars:
            print(f"  - {var}")
        print("\nPlease set these variables in your .env file.")
        return
    
    try:
        await example_with_connection_settings()
        await example_with_explicit_parameters()
    except Exception as e:
        print(f"\nError: {e}")
        print("\nPlease ensure:")
        print("  1. Your Azure AD App Registration has correct permissions")
        print("  2. Your Copilot Studio agent is published")
        print("  3. All environment variables are correctly set")


if __name__ == "__main__":
    asyncio.run(main())
