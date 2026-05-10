## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.
## 2025-02-18 - Prevent SSRF in MCP Toolset Initialization
**Vulnerability:** FastMCPToolset was initialized with potentially user-provided or environmentally controlled URLs without validation, allowing for Server-Side Request Forgery (SSRF) if the URL points to cloud metadata services or internal networks.
**Learning:** Initializing connections to external tools/servers (like FastMCPToolset) using unvalidated strings is risky in an agentic context where inputs could be manipulated.
**Prevention:** Implement strict URL validation (e.g., `is_safe_mcp_url`) that checks allowed schemes (`http`/`https`) and explicitly blocks known metadata IP addresses (e.g., `169.254.169.254`) and hostnames (e.g., `metadata.google.internal`) before instantiating the connection.
