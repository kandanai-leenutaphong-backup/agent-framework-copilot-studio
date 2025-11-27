# Copyright (c) Microsoft. All rights reserved.

import asyncio
import os
from dotenv import load_dotenv
from agent_framework.microsoft import CopilotStudioAgent

"""
Copilot Studio Agent Basic Example

This sample demonstrates basic usage of CopilotStudioAgent with automatic configuration
from environment variables, showing both streaming and non-streaming responses.
"""

# Load environment variables from .env file
load_dotenv()


async def non_streaming_example() -> None:
    """Example of non-streaming response (get the complete result at once)."""
    print("=== Non-streaming Response Example ===")

    agent = CopilotStudioAgent()

    query = "What is the capital of France?"
    print(f"User: {query}")
    result = await agent.run(query)
    print(f"Agent: {result}\n")


async def streaming_example() -> None:
    """Example of streaming response (get results as they are generated)."""
    print("=== Streaming Response Example ===")

    agent = CopilotStudioAgent()

    query = "What is the capital of Spain?"
    print(f"User: {query}")
    print("Agent: ", end="", flush=True)
    async for chunk in agent.run_stream(query):
        if chunk.text:
            print(chunk.text, end="", flush=True)
    print("\n")


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
        await non_streaming_example()
        # await streaming_example()
    except Exception as e:
        print(f"\nError: {e}")
        print("\nPlease ensure:")
        print("  1. Your Azure AD App Registration has correct permissions")
        print("  2. Your Copilot Studio agent is published")
        print("  3. All environment variables are correctly set")


if __name__ == "__main__":
    asyncio.run(main())
