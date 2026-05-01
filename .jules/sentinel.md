
## 2025-02-26 - [Prompt Injection/SSRF via Unvalidated LLM Prompts]
**Vulnerability:** The `github_issue_url` parameter was incorporated directly into the AI agent's prompt without any URL validation, exposing the application to Prompt Injection and SSRF attacks.
**Learning:** External inputs passed directly into LLM prompts can be manipulated to instruct the agent to perform unauthorized actions or access unintended internal/external endpoints via the MCP tools.
**Prevention:** Always implement strict input validation (e.g., using `urllib.parse` to enforce scheme, domain, and path constraints) before incorporating external inputs into LLM prompts.
