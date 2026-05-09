## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-09 - SSRF Vulnerability in MCP Toolset Initialization
**Vulnerability:** The `mcp_server_url` input used to initialize `FastMCPToolset` in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py` was not strictly validated.
**Learning:** Permitting unvalidated external or environment-provided URLs when establishing toolset connections (like MCP servers) poses a Server-Side Request Forgery (SSRF) risk. An attacker could potentially direct the agent to connect to cloud metadata endpoints (e.g., `169.254.169.254`) or unintended internal IP addresses.
**Prevention:** Always validate toolset connection URLs explicitly before initialization. Enforce acceptable schemes (`http`/`https`) and explicitly deny known cloud metadata IPs or internal hostnames using robust parsing to prevent SSRF in Pydantic AI applications.
