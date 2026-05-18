## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-02 - SSRF Vulnerability via Unvalidated MCP Server URLs
**Vulnerability:** External input or environment variables specifying the MCP server URL were passed to `FastMCPToolset` without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Initializing connections to external tools like MCP servers using unvalidated URLs exposes the system to Server-Side Request Forgery (SSRF) vulnerabilities, where the application could be tricked into querying internal or unintended domains (e.g., cloud metadata endpoints).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before initializing network connections. Enforce allowed schemes (`http`/`https`) and explicitly block known cloud metadata hostnames/IPs (e.g., `169.254.169.254`, `metadata.google.internal`, `fd00:ec2::254`).
