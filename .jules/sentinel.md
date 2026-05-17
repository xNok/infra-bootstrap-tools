## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.
## 2026-05-03 - SSRF Vulnerability in MCP Toolset Initialization
**Vulnerability:** External input (MCP Server URL) was passed to FastMCPToolset without validation in agent.py and jules_workflow.py.
**Learning:** Initializing connections to external URLs directly provided by users or environment configurations can lead to Server-Side Request Forgery (SSRF), exposing internal metadata endpoints.
**Prevention:** Always validate external URLs using strict parsing (like urllib.parse) and explicitly block known metadata endpoints (e.g., 169.254.169.254) before utilizing them for network connections.
