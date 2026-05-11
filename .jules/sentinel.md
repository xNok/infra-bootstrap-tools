## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2024-05-11 - SSRF Prevention for External Toolset Initialization
**Vulnerability:** FastMCPToolset instantiation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py` was vulnerable to Server-Side Request Forgery (SSRF) as it accepted unvalidated user-supplied or environment URLs (`MCP_SERVER_URL`).
**Learning:** External toolsets or Pydantic AI integrations that accept URLs will often attempt to fetch external schemas/configurations. Attackers could exploit this to query internal cloud metadata endpoints (e.g., `169.254.169.254`) and exfiltrate sensitive IAM credentials or instance data.
**Prevention:** Always validate URLs passed into external initialization methods. Ensure URLs strictly use `http` or `https` schemes, and explicitly block known metadata domains/IPs (`169.254.169.254`, `metadata.google.internal`) before network requests are initiated.
