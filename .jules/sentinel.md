## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-04 - SSRF via Unvalidated MCP Server URL
**Vulnerability:** The `MCP_SERVER_URL` in `agentic/jules/agent.py` and `agentic/workflows/jules_workflow.py` could be influenced by environment variables or arguments and passed directly to `FastMCPToolset` without validation.
**Learning:** Initializing connections to external tools/servers using unvalidated URLs (even if sourced from environment variables) can lead to Server-Side Request Forgery (SSRF) if those inputs are ever manipulatable. This is especially dangerous in cloud environments where `FastMCPToolset` might attempt to resolve metadata IP addresses (e.g., `169.254.169.254`).
**Prevention:** Enforce strict URL validation for all external connections, ensuring that only HTTP/HTTPS schemes are used and explicitly blocking known cloud metadata hostnames and IP addresses.
