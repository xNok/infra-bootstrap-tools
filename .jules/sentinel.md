## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2024-05-24 - SSRF via Unvalidated MCP Server URL
**Vulnerability:** The `mcp_server_url` (either user-provided or retrieved via `MCP_SERVER_URL` env variable) was passed directly to the `FastMCPToolset` in `agentic/workflows/jules_workflow.py` without proper validation, creating an SSRF (Server-Side Request Forgery) vulnerability.
**Learning:** Initializing toolsets like `FastMCPToolset` with unsanitized environment/user URLs could allow an attacker to point the MCP server to cloud metadata endpoints (`169.254.169.254` or `metadata.google.internal`), leading to sensitive cloud token exfiltration or interaction with internal network resources.
**Prevention:** Added `is_safe_mcp_url` validation to explicitly enforce allowed URL schemes (`http` / `https`) and actively block common cloud metadata endpoints and IP addresses before executing external HTTP requests.
