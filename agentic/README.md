# Pydantic AI Agent for Jules

This directory contains a demonstration of a Pydantic AI agent designed to assign tasks to the Jules agent via an MCP (Multi-Cloud Platform) server. The agent takes a GitHub issue URL as input and creates a new session for Jules to work on resolving the issue.

## Description

The core of this demonstration is `agent.py`, a Python script that uses the `pydantic-ai` library to create an intelligent agent. The agent is equipped with a tool that can communicate with the Jules API to create new sessions. When provided with a GitHub issue URL, the agent intelligently calls this tool to assign the task.

The Pydantic models in `models.py` are generated based on the OpenAPI specification in `jules.schema.json`, ensuring that all communication with the API is type-safe and validated.

## Requirements

*   Python 3.9+
*   `pydantic-ai`
*   `requests`
*   An OpenAI API key

## Setup

1.  **Install Dependencies:**
    Install the necessary Python libraries using pip:
    ```bash
    pip install "pydantic-ai-slim[openai]" requests
    ```

2.  **Configure API Key:**
    The agent uses an OpenAI model to understand prompts and decide when to call its tools. You must have an OpenAI API key set as an environment variable.

    ```bash
    export OPENAI_API_KEY="your-openai-api-key-here"
    ```

## Usage

To run the agent, execute the `agent.py` script from your terminal, providing the full URL of a GitHub issue as a command-line argument.

**Example:**

```bash
python3 agentic/agent.py https://github.com/your-org/your-repo/issues/123
```

The agent will then process the request, and you will see log messages indicating the steps it's taking, including the final output from the API call.

### How It Works

1.  The `main` function in `agent.py` parses the command-line arguments.
2.  A prompt is constructed to instruct the `pydantic-ai` agent to use its `assign_task_to_jules` tool.
3.  The agent, powered by an LLM, understands the prompt and calls the tool with the GitHub issue URL as the argument.
4.  The `assign_task_to_jules` function handles the logic of:
    *   Parsing the GitHub URL to extract the owner and repository.
    *   Constructing a `CreateSessionRequest` payload using the Pydantic models.
    *   Sending a POST request to the Jules API's `/sessions` endpoint.
    *   Printing the result of the operation.

## File Descriptions

*   **`agent.py`**: The main script that defines and runs the `pydantic-ai` agent. It includes the logic for the tool that assigns tasks to Jules.
*   **`models.py`**: Contains the Pydantic models that represent the data structures of the Jules API, based on the OpenAPI schema. This ensures data validation and consistency.
*   **`jules.schema.json`**: The OpenAPI 3.0 specification for the Jules API. This file serves as the "source of truth" for the API's endpoints and data models.
