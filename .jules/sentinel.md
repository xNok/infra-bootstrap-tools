## 2024-05-24 - [Fix SSRF vulnerability in FastMCPToolset Initialization]
**Vulnerability:** The FastMCPToolset initialization via `MCP_SERVER_URL` in multiple Python scripts allowed Server-Side Request Forgery (SSRF) since the provided URLs weren't validated for internal endpoints or cloud metadata boundaries.
**Learning:** Tools accessing external inputs natively assume internal connectivity might be safe, but can be targeted to access internal infrastructure specifically like cloud metadata instance endpoints.
**Prevention:** Validate environment variable and function-argument-based URLs using `urllib.parse` explicitly rejecting missing schemes, non HTTP/S schemas, and metadata internal target IP/hostnames.
