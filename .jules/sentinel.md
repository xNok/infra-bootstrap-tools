## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2024-05-24 - SSRF vulnerability in FastMCPToolset initialization
**Vulnerability:** The MCP server URL used to initialize `FastMCPToolset` in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py` was not validated. This could allow an attacker to pass malicious URLs (e.g., via `MCP_SERVER_URL` environment variable) and trigger an SSRF attack against internal endpoints like cloud metadata services (e.g., `169.254.169.254`).
**Learning:** External or configurable URLs passed to sensitive functions like `FastMCPToolset` must be validated to ensure they conform to expected schemes and do not target internal or restricted IP ranges.
**Prevention:** Implemented `is_safe_mcp_server_url` in `agentic/jules/url_validation.py` to enforce `http` or `https` schemes and explicitly block known cloud metadata hostnames/IPs before toolset initialization.
