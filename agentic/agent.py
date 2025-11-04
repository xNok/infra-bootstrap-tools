#!/usr/bin/env python3
"""
A Pydantic AI agent script to assign tasks to the Jules agent via the MCP server.
"""

import argparse
import sys

from pydantic_ai import Agent
from pydantic_ai.toolset import FastMCPToolset

# The user has indicated that the MCP server is running locally for this demonstration.
MCP_SERVER_URL = "http://localhost:8000/mcp"

def main():
    """Defines the command-line interface and runs the agent."""
    parser = argparse.ArgumentParser(description="Assign a GitHub issue task to the Jules agent using Pydantic AI and an MCP server.")
    parser.add_argument("github_issue_url", type=str, help="The full URL of the GitHub issue to be assigned.")
    args = parser.parse_args()

    try:
        # Initialize a toolset that points to the MCP server.
        # This toolset will automatically discover the tools provided by the server.
        toolset = FastMCPToolset(MCP_SERVER_URL)

        # Initialize the Pydantic AI Agent with the MCP toolset.
        # We assume any necessary API keys for the LLM (e.g., OPENAI_API_KEY)
        # are available in the environment.
        agent = Agent(
            'openai:gpt-4o',
            toolsets=[toolset],
            system_prompt="You are an agent assistant. Your primary function is to assign tasks to the Jules agent by calling the available tools from the MCP server with the correct parameters."
        )

        # Create a clear prompt for the pydantic-ai agent, instructing it to use the
        # appropriate tool from the MCP server to handle the GitHub issue.
        # The agent's LLM will match this prompt to the signature of the correct
        # tool discovered from the MCP server (e.g., a tool named 'assign_task'
        # that accepts a 'github_issue_url').
        prompt = f"Please assign the task from this GitHub issue: {args.github_issue_url}"

        print(f"INFO: Running Pydantic AI agent with prompt: '{prompt}'")

        # Execute the agent synchronously. The agent will interpret the prompt
        # and call the appropriate tool from the MCP toolset.
        result = agent.run_sync(prompt)

        print("\n--- Agent Final Output ---")
        print(result.output)
        print("--------------------------")

    except Exception as e:
        print(f"Error: An unexpected error occurred. Details: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
