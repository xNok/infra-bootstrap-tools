## 2026-05-02 - SSRF and Prompt Injection via Unvalidated Issue URLs
**Vulnerability:** External input (`github_issue_url`) was directly interpolated into the user prompt passed to the LLM agent without validation in `agentic/workflows/jules_workflow.py` and `agentic/jules/agent.py`.
**Learning:** Passing unsanitized URLs to an LLM exposes the system to prompt injection (where a malicious URL contains instructions overriding the agent's intent) and SSRF (where the LLM agent could be tricked into querying internal or unintended domains).
**Prevention:** Always validate external URLs using strict parsing (like `urllib.parse`) before embedding them in prompts. Enforce allowed schemes (`https`), specific domains (`github.com`), and strictly validate path structures to ensure only intended inputs reach the LLM.

## 2026-05-22 - SSRF vulnerability initializing FastMCPToolset
**Vulnerability:** FastMCPToolset was being initialized with an arbitrary unvalidated `mcp_server_url`.
**Learning:** Directly passing user-supplied or environment-based URLs to network fetching libraries (like FastMCPToolset does) without strict validation can result in Server-Side Request Forgery (SSRF). Attackers can probe internal networks or access sensitive metadata services.
**Prevention:** To prevent SSRF when initializing external toolsets, validate the URL scheme (`http`/`https`) and explicitly block known cloud metadata hostnames (`metadata.google.internal`) and IPs (`169.254.169.254`, `fd00:ec2::254`). Use `socket.getaddrinfo` to resolve the hostname and check the resulting IP addresses with the `ipaddress` module to prevent bypasses via DNS rebinding, CNAMEs, or decimal/octal encodings.
