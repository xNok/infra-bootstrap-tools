#!/usr/bin/env python3
"""
A Pydantic AI agent script to assign tasks to the Jules agent via the MCP server.
"""

import argparse
import json
import re
import sys
from urllib.parse import urlparse

from pydantic_ai import Agent

# Assuming models.py is in the same directory and contains the Pydantic models
# corresponding to the jules.schema.json
try:
    from models import CreateSessionRequest, SourceContext, GithubRepoContext
except ImportError:
    print("Error: 'models.py' not found. Please ensure it is in the same directory.", file=sys.stderr)
    sys.exit(1)


# The base URL for the Jules API.
# Per the user, this is served via mcp hub, so the URL might need to be configured
# based on the deployment environment. The value from the schema is used as a default.
JULES_API_URL = "https://jules.googleapis.com/v1alpha"

# Initialize the pydantic-ai Agent.
# The user indicated that credentials will be handled by the MCP server,
# so we assume any necessary API keys for the LLM (e.g., OPENAI_API_KEY)
# are available in the environment. We'll use a standard OpenAI model as a placeholder.
jules_assigner_agent = Agent(
    'openai:gpt-4o',
    system_prompt="You are an agent assistant. Your primary function is to assign tasks to the Jules agent by calling the available tools with the correct parameters.",
)


@jules_assigner_agent.tool_plain
def assign_task_to_jules(github_issue_url: str) -> str:
    """
    Assigns a task to the Jules agent by creating a new session via the MCP server.

    Args:
        github_issue_url: The full URL of the GitHub issue that defines the task.

    Returns:
        A string containing a confirmation message with the new session details
        or an error message if the process fails.
    """
    print(f"INFO: Received request to assign task from: {github_issue_url}")

    # 1. Parse the GitHub URL to extract owner and repository names.
    # Example URL: https://github.com/owner/repo/issues/123
    match = re.match(r"https://github\.com/([^/]+)/([^/]+)/issues/\d+", github_issue_url)
    if not match:
        error_msg = f"Error: Invalid GitHub issue URL format. Expected format: https://github.com/owner/repo/issues/number. Received: {github_issue_url}"
        print(error_msg, file=sys.stderr)
        return error_msg

    owner, repo = match.groups()
    print(f"INFO: Parsed owner='{owner}', repo='{repo}'")

    # 2. Construct the request payload using the Pydantic models.
    try:
        source_context = SourceContext(
            source=f"sources/github/{owner}/{repo}",
            github_repo_context=GithubRepoContext(starting_branch="main")  # Assuming 'main' as the default branch
        )

        request_body = CreateSessionRequest(
            prompt=f"Please address the following GitHub issue: {github_issue_url}",
            source_context=source_context,
            title=f"Resolve GitHub Issue: {owner}/{repo}"
        )

        # Convert the Pydantic model to a dictionary for the JSON payload.
        # `by_alias=True` ensures field names match the API schema (e.g., 'sourceContext').
        # `exclude_none=True` omits optional fields that are not set.
        payload = request_body.model_dump(by_alias=True, exclude_none=True)

    except Exception as e:
        error_msg = f"Error: Failed to create the request body. Details: {e}"
        print(error_msg, file=sys.stderr)
        return error_msg

    # 3. Simulate handing off the request to the MCP server.
    # In a real-world scenario, the MCP server would provide the implementation
    # for this tool, and this agent would only be responsible for invoking it.
    # Here, we'll print the payload to demonstrate that the agent has correctly
    # processed the input and is ready to make the API call.

    print("INFO: Task handoff to MCP server for execution.")
    print(f"INFO: Payload to be sent to {JULES_API_URL}/sessions:\n{json.dumps(payload, indent=2)}")

    # Simulate a successful response from the MCP server.
    simulated_session_name = f"sessions/simulated-{repo}-{owner}"
    success_msg = f"Successfully simulated the creation of session: {simulated_session_name}"
    print(f"INFO: {success_msg}")

    return success_msg


def main():
    """Defines the command-line interface and runs the agent."""
    parser = argparse.ArgumentParser(description="Assign a GitHub issue task to the Jules agent using Pydantic AI.")
    parser.add_argument("github_issue_url", type=str, help="The full URL of the GitHub issue to be assigned.")
    args = parser.parse_args()

    # Create a clear prompt for the pydantic-ai agent, instructing it to use the tool.
    prompt = f"Use the 'assign_task_to_jules' tool to assign the task from this GitHub issue: {args.github_issue_url}"

    print("INFO: Running Pydantic AI agent to process the request...")

    # Execute the agent synchronously. The agent will interpret the prompt
    # and call the `assign_task_to_jules` tool with the extracted URL.
    result = jules_assigner_agent.run_sync(prompt)

    print("\n--- Agent Final Output ---")
    print(result.output)
    print("--------------------------")


if __name__ == "__main__":
    main()
