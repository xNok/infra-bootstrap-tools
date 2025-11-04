# Pydantic AI Agent for Jules

This directory contains a demonstration of a Pydantic AI agent designed to assign tasks to the Jules agent by interacting with a running MCP (Multi-Cloud Platform) server.

## Description

The core of this demonstration is `agent.py`, a Python script that uses the `pydantic-ai` library to create an intelligent agent. The agent is configured to connect to an MCP server, which provides it with a set of tools. When given a prompt containing a GitHub issue URL, the agent intelligently selects and uses the appropriate tool from the MCP server to assign the task to Jules.

This example showcases how `pydantic-ai` can be used to create agents that dynamically discover and use tools from a central server, rather than having them defined locally.

## Requirements

*   Python 3.9+
*   An OpenAI API key
*   A running MCP server at `http://localhost:8000/mcp` that provides the necessary tools.

## Setup

1.  **Install Dependencies:**
    Install the necessary Python libraries using pip from the `requirements.txt` file:
    ```bash
    pip install -r agentic/requirements.txt
    ```

2.  **Configure API Key:**
    The agent uses an OpenAI model to understand prompts and decide which tool to call. You must have an OpenAI API key set as an environment variable.

    ```bash
    export OPENAI_API_KEY="your-openai-api-key-here"
    ```

3.  **Ensure MCP Server is Running:**
    This agent requires a running MCP server at `http://localhost:8000/mcp`. The server must provide the tools that the agent will use to assign tasks.

## Usage

To run the agent, execute the `agent.py` script from your terminal, providing the full URL of a GitHub issue as a command-line argument.

**Example:**

```bash
python3 agentic/agent.py https://github.com/your-org/your-repo/issues/123
```

The agent will then connect to the MCP server, discover the available tools, and use the appropriate one to handle the GitHub issue.

### How It Works

1.  The `main` function in `agent.py` parses the command-line arguments.
2.  It initializes a `FastMCPToolset`, pointing to the local MCP server. This toolset automatically discovers the tools exposed by the server.
3.  A `pydantic-ai` `Agent` is created and configured to use this toolset.
4.  A prompt is constructed containing the GitHub issue URL.
5.  The agent's LLM interprets the prompt, matches it to the signature of a tool provided by the MCP server, and invokes that tool with the correct parameters.

## File Descriptions

*   **`agent.py`**: The main script that defines and runs the `pydantic-ai` agent. It connects to the MCP server to discover and use tools.
*   **`models.py`**: Contains the Pydantic models that represent the data structures of the Jules API. These are used by the tools on the MCP server.
*   **`jules.schema.json`**: The OpenAPI 3.0 specification for the Jules API, which defines the contract for the tools.
*   **`requirements.txt`**: The Python dependencies for the agent.
