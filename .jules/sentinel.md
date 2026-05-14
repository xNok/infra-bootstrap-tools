## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-02 - SSRF and Prompt Injection via Unvalidated MCP Server URLs
**Vulnerability:** External input (`mcp_server_url` or `MCP_SERVER_URL`) was passed to initialize external connections via `FastMCPToolset` without validation, posing an SSRF risk.
**Learning:** Validating URLs passed to internal services or libraries is crucial to prevent the application from making requests to arbitrary locations, including cloud metadata endpoints which can expose sensitive credentials.
**Prevention:** Use a validation function like `is_safe_mcp_server_url` that strictly checks the URL scheme (`http` or `https`) and explicitly blocks known cloud metadata IPs (`169.254.169.254`) and hostnames (`metadata.google.internal`).
