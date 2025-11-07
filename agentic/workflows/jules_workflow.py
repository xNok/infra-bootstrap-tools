"""
Prefect workflows for Jules agent.

This module provides Prefect-based workflow orchestration for the Jules agent,
enabling scheduled and on-demand execution of GitHub issue automation tasks.
"""

import os
import sys
from typing import Optional

from prefect import flow, task
from pydantic_ai import Agent
from pydantic_ai.toolset import FastMCPToolset


@task(name="initialize_mcp_toolset", retries=2, retry_delay_seconds=5)
def initialize_mcp_toolset(mcp_server_url: str) -> FastMCPToolset:
    """
    Initialize the MCP toolset connection.
    
    Args:
        mcp_server_url: URL of the MCP server
        
    Returns:
        Initialized FastMCPToolset instance
        
    Raises:
        ConnectionError: If unable to connect to MCP server
    """
    try:
        toolset = FastMCPToolset(mcp_server_url)
        return toolset
    except Exception as e:
        raise ConnectionError(f"Failed to initialize MCP toolset: {e}") from e


@task(name="create_jules_agent")
def create_jules_agent(toolset: FastMCPToolset, model: str = "openai:gpt-4o") -> Agent:
    """
    Create and configure the Jules agent.
    
    Args:
        toolset: Initialized MCP toolset
        model: LLM model to use (default: openai:gpt-4o)
        
    Returns:
        Configured Agent instance
    """
    agent = Agent(
        model,
        toolsets=[toolset],
        system_prompt=(
            "You are an agent assistant. Your primary function is to assign tasks "
            "to the Jules agent by calling the available tools from the MCP server "
            "with the correct parameters."
        )
    )
    return agent


@task(name="assign_github_issue", retries=1)
def assign_github_issue(agent: Agent, github_issue_url: str) -> str:
    """
    Assign a GitHub issue using the Jules agent.
    
    Args:
        agent: Configured Agent instance
        github_issue_url: URL of the GitHub issue to assign
        
    Returns:
        Agent's response/output
        
    Raises:
        RuntimeError: If the agent fails to process the issue
    """
    try:
        prompt = f"Please assign the task from this GitHub issue: {github_issue_url}"
        result = agent.run_sync(prompt)
        return result.output
    except Exception as e:
        raise RuntimeError(f"Failed to assign GitHub issue: {e}") from e


@flow(
    name="jules-agent-workflow",
    description="Workflow to assign GitHub issues to Jules agent via MCP server",
    log_prints=True,
)
def jules_agent_workflow(
    github_issue_url: str,
    mcp_server_url: Optional[str] = None,
    model: Optional[str] = None,
) -> str:
    """
    Main Prefect workflow for Jules agent GitHub issue assignment.
    
    This workflow:
    1. Connects to the MCP server
    2. Initializes the Jules agent
    3. Assigns the GitHub issue
    
    Args:
        github_issue_url: URL of the GitHub issue to assign
        mcp_server_url: URL of the MCP server (defaults to http://localhost:8000/mcp)
        model: LLM model to use (defaults to openai:gpt-4o)
        
    Returns:
        Agent's response/output
        
    Raises:
        ValueError: If required environment variables are missing
        ConnectionError: If unable to connect to MCP server
        RuntimeError: If the agent fails to process the issue
        
    Environment Variables:
        OPENAI_API_KEY: Required for OpenAI model access
        MCP_SERVER_URL: Optional, defaults to http://localhost:8000/mcp
        LLM_MODEL: Optional, defaults to openai:gpt-4o
    """
    # Validate required environment variables
    if not os.getenv("OPENAI_API_KEY"):
        raise ValueError("OPENAI_API_KEY environment variable is required")
    
    # Use provided or default values
    mcp_url = mcp_server_url or os.getenv("MCP_SERVER_URL", "http://localhost:8000/mcp")
    llm_model = model or os.getenv("LLM_MODEL", "openai:gpt-4o")
    
    print(f"Connecting to MCP server at: {mcp_url}")
    print(f"Using LLM model: {llm_model}")
    print(f"Processing GitHub issue: {github_issue_url}")
    
    # Initialize MCP toolset
    toolset = initialize_mcp_toolset(mcp_url)
    
    # Create Jules agent
    agent = create_jules_agent(toolset, llm_model)
    
    # Assign the GitHub issue
    result = assign_github_issue(agent, github_issue_url)
    
    print(f"Successfully assigned issue. Result: {result}")
    return result


if __name__ == "__main__":
    """
    CLI entry point for testing the workflow locally.
    
    Usage:
        python -m agentic.workflows.jules_workflow https://github.com/owner/repo/issues/123
    """
    if len(sys.argv) < 2:
        print("Usage: python -m agentic.workflows.jules_workflow <github_issue_url>")
        sys.exit(1)
    
    issue_url = sys.argv[1]
    result = jules_agent_workflow(issue_url)
    print(f"\n--- Workflow Complete ---")
    print(f"Result: {result}")
