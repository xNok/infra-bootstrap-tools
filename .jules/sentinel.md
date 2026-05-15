## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-15 - [SSRF vulnerability with FastMCPToolset]
**Vulnerability:** The `FastMCPToolset` in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py` was initialized directly with user-provided/environmental URLs without validation.
**Learning:** External libraries and toolsets interacting over network boundaries are susceptible to Server-Side Request Forgery (SSRF). Attackers could provide cloud metadata endpoints (e.g., `169.254.169.254`) causing internal credentials or sensitive internal infrastructure to be exposed or called by the executing agent.
**Prevention:** Validate all URLs before passing them to external toolset initializations. Always check the scheme is restricted to `http`/`https` and block known internal/cloud metadata IP addresses and hostnames.
