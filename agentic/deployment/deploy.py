#!/usr/bin/env python3
"""
Deployment script for Jules agent workflow to Prefect.

This script handles:
1. Preloading MCP servers (GitHub and Jules) to mcp-hub
2. Deploying the Jules agent workflow to Prefect
3. Configuring necessary environment variables
"""

import argparse
import concurrent.futures
import json
import os
import sys
import time

import requests


def check_mcp_hub_health(mcp_hub_url: str, max_retries: int = 30, delay: int = 2) -> bool:
    """
    Check if MCP Hub is healthy and ready.

    Args:
        mcp_hub_url: Base URL of MCP Hub
        max_retries: Maximum number of connection attempts
        delay: Delay between retries in seconds

    Returns:
        True if MCP Hub is healthy, False otherwise
    """
    print(f"Checking MCP Hub health at {mcp_hub_url}...")
    with requests.Session() as session:
        for attempt in range(max_retries):
            try:
                response = session.get(f"{mcp_hub_url}/health", timeout=5)
                if response.status_code == 200:
                    print("✓ MCP Hub is healthy")
                    return True
            except requests.exceptions.RequestException as e:
                if attempt < max_retries - 1:
                    print(f"  Attempt {attempt + 1}/{max_retries}: Waiting for MCP Hub... ({e})")
                    time.sleep(delay)
                else:
                    print(f"✗ Failed to connect to MCP Hub after {max_retries} attempts")
                    return False
    return False


def preload_github_mcp_server(mcp_hub_url: str, github_token: str) -> bool:
    """
    Preload GitHub MCP server to mcp-hub.

    Args:
        mcp_hub_url: Base URL of MCP Hub
        github_token: GitHub personal access token

    Returns:
        True if successful, False otherwise
    """
    print("\nPreloading GitHub MCP server...")

    config = {
        "name": "github",
        "type": "http",
        "url": "https://api.githubcopilot.com/mcp/",
        "headers": {"Authorization": f"Bearer {github_token}"},
    }

    try:
        response = requests.post(
            f"{mcp_hub_url}/api/servers",
            json=config,
            headers={"Content-Type": "application/json"},
            timeout=30,
        )

        if response.status_code in (200, 201):
            print("✓ GitHub MCP server preloaded successfully")
            return True
        elif response.status_code == 409:
            print("✓ GitHub MCP server already exists")
            return True
        else:
            print(
                f"✗ Failed to preload GitHub MCP server: {response.status_code} - {response.text}"
            )
            return False
    except requests.exceptions.RequestException as e:
        print(f"✗ Error preloading GitHub MCP server: {e}")
        return False


def preload_jules_mcp_server(mcp_hub_url: str, jules_api_key: str, schema_path: str) -> bool:
    """
    Preload Jules MCP server to mcp-hub using OpenAPI spec.

    Args:
        mcp_hub_url: Base URL of MCP Hub
        jules_api_key: Jules API key
        schema_path: Path to jules.schema.json OpenAPI spec

    Returns:
        True if successful, False otherwise
    """
    print("\nPreloading Jules MCP server from OpenAPI spec...")

    # Read the OpenAPI schema
    try:
        with open(schema_path, "r") as f:
            schema = json.load(f)
    except Exception as e:
        print(f"✗ Failed to read Jules OpenAPI schema: {e}")
        return False

    config = {
        "name": "jules",
        "type": "openapi",
        "spec": schema,
        "auth": {"type": "apiKey", "key": "X-Goog-Api-Key", "value": jules_api_key},
    }

    try:
        response = requests.post(
            f"{mcp_hub_url}/api/servers",
            json=config,
            headers={"Content-Type": "application/json"},
            timeout=30,
        )

        if response.status_code in (200, 201):
            print("✓ Jules MCP server preloaded successfully")
            return True
        elif response.status_code == 409:
            print("✓ Jules MCP server already exists")
            return True
        else:
            print(f"✗ Failed to preload Jules MCP server: {response.status_code} - {response.text}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"✗ Error preloading Jules MCP server: {e}")
        return False


def preload_mcp_servers(
    mcp_hub_url: str, github_token: str, jules_api_key: str, schema_path: str
) -> bool:
    """
    Preload MCP servers (GitHub and Jules) in parallel.

    Args:
        mcp_hub_url: Base URL of MCP Hub
        github_token: GitHub personal access token
        jules_api_key: Jules API key
        schema_path: Path to jules.schema.json OpenAPI spec

    Returns:
        True if all servers were preloaded successfully, False otherwise
    """
    print("\nPreloading MCP servers in parallel...")

    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_github = executor.submit(preload_github_mcp_server, mcp_hub_url, github_token)
        future_jules = executor.submit(
            preload_jules_mcp_server, mcp_hub_url, jules_api_key, schema_path
        )

        # Wait for both to complete
        success_github = future_github.result()
        success_jules = future_jules.result()

    return success_github and success_jules


def deploy_jules_workflow(prefect_api_url: str, work_pool_name: str = "default-agent-pool") -> bool:
    """
    Deploy Jules agent workflow to Prefect.

    Args:
        prefect_api_url: Prefect API URL
        work_pool_name: Name of the work pool to deploy to

    Returns:
        True if successful, False otherwise
    """
    print("\nDeploying Jules agent workflow to Prefect...")
    print(f"Prefect API URL: {prefect_api_url}")

    # Set Prefect API URL
    os.environ["PREFECT_API_URL"] = prefect_api_url

    try:
        # Import the workflow
        from agentic.workflows.jules_workflow import jules_agent_workflow

        # Deploy using serve (for local deployment)
        print("Starting workflow deployment with serve...")
        print("Note: This will run in the foreground. Press Ctrl+C to stop.")

        # For local deployment, we use serve instead of deploy
        jules_agent_workflow.serve(
            name="jules-agent-deployment",
            tags=["jules", "github", "automation"],
            description="Automated GitHub issue assignment via Jules agent",
            version="1.0.0",
        )

        return True
    except Exception as e:
        print(f"✗ Failed to deploy workflow: {e}")
        import traceback

        traceback.print_exc()
        return False


def main():
    """Main entry point for deployment script."""
    parser = argparse.ArgumentParser(
        description="Deploy Jules agent workflow to Prefect with MCP server preloading"
    )
    parser.add_argument(
        "--mcp-hub-url",
        default="http://localhost:3000",
        help="MCP Hub URL (default: http://localhost:3000)",
    )
    parser.add_argument(
        "--prefect-api-url",
        default="http://localhost:4200/api",
        help="Prefect API URL (default: http://localhost:4200/api)",
    )
    parser.add_argument(
        "--skip-mcp-preload", action="store_true", help="Skip MCP server preloading"
    )
    parser.add_argument(
        "--deploy-only",
        action="store_true",
        help="Only deploy workflow, skip health checks and MCP preloading",
    )

    args = parser.parse_args()

    # Check for required environment variables
    github_token = os.getenv("GITHUB_TOKEN")
    jules_api_key = os.getenv("JULES_API_KEY")
    google_api_key = os.getenv("GOOGLE_API_KEY")
    openai_api_key = os.getenv("OPENAI_API_KEY")

    # Check which model will be used
    llm_model = os.getenv("LLM_MODEL", "google-gla:gemini-1.5-flash")

    missing_vars = []
    if not github_token:
        missing_vars.append("GITHUB_TOKEN")
    if not jules_api_key:
        missing_vars.append("JULES_API_KEY")

    # Check for appropriate API key based on model
    if llm_model.startswith("google") or llm_model.startswith("gemini"):
        if not google_api_key:
            missing_vars.append("GOOGLE_API_KEY (required for Google models)")
    elif llm_model.startswith("openai"):
        if not openai_api_key:
            missing_vars.append("OPENAI_API_KEY (required for OpenAI models)")
    else:
        # Default to Google
        if not google_api_key:
            missing_vars.append("GOOGLE_API_KEY (default model requires this)")

    if missing_vars:
        print("✗ Error: Missing required environment variables:")
        for var in missing_vars:
            print(f"  - {var}")
        print("\nPlease set these variables before running the deployment.")
        print("See .env.example for reference.")
        sys.exit(1)

    print("=" * 70)
    print("Jules Agent Workflow Deployment")
    print("=" * 70)

    success = True

    if not args.deploy_only:
        # Check MCP Hub health
        if not check_mcp_hub_health(args.mcp_hub_url):
            print("\n✗ MCP Hub is not available. Please start the stack first:")
            print("  ibt stacks run prefect mcp-hub")
            sys.exit(1)

        # Preload MCP servers
        if not args.skip_mcp_preload:
            schema_path = os.path.join(
                os.path.dirname(os.path.dirname(__file__)), "jules.schema.json"
            )

            success = preload_mcp_servers(
                args.mcp_hub_url, github_token, jules_api_key, schema_path
            )

            if not success:
                print("\n✗ Failed to preload MCP servers")
                sys.exit(1)

    # Deploy workflow
    if success:
        success = deploy_jules_workflow(args.prefect_api_url)

    if success:
        print("\n" + "=" * 70)
        print("✓ Deployment completed successfully!")
        print("=" * 70)
        print("\nNext steps:")
        print("1. Access Prefect UI at: http://localhost:4200")
        print("2. Access MCP Hub at: http://localhost:3000")
        print("3. Run the workflow with a GitHub issue URL")
    else:
        print("\n✗ Deployment failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
