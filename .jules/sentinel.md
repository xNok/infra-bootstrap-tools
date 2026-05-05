## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-05 - SSRF via FastMCPToolset Initialization
**Vulnerability:** External MCP Server URLs were directly initialized in `FastMCPToolset` without checking if the URL points to a cloud metadata endpoint (like `169.254.169.254` or `metadata.google.internal`).
**Learning:** Instantiating external network components using unvalidated URLs risks SSRF. FastMCPToolset makes network requests to fetch the openapi schema from the provided server URL. If an attacker controls the `MCP_SERVER_URL` via environment variables or user input, they could point it to cloud instance metadata, potentially leaking cloud credentials.
**Prevention:** Explicitly validate URLs before using them to initialize external connections. Ensure the URL scheme is strictly restricted to expected ones (`http` or `https`) and explicitly block known cloud metadata hostnames to protect cloud environments.
