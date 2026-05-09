"""
URL validation utilities for Jules agent.

Centralizes security-sensitive URL validation to prevent prompt injection
and SSRF attacks when processing external user inputs.
"""

import urllib.parse


def is_valid_github_issue_url(url: str) -> bool:
    """
    Validates that the provided URL is a strict GitHub issue URL.

    Accepted format: https://github.com/<owner>/<repo>/issues/<number>
    Rejects any URL with extra path segments, query parameters, fragments,
    non-standard ports, or non-https schemes.

    Args:
        url: The URL string to validate.

    Returns:
        True if the URL exactly matches the expected GitHub issue format,
        False otherwise.
    """
    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme != "https":
            return False
        if parsed.hostname != "github.com":
            return False
        # Reject non-standard ports; parsed.hostname strips the port so we check separately.
        if parsed.port is not None:
            return False
        if parsed.params or parsed.query or parsed.fragment:
            return False
        path_parts = parsed.path.strip("/").split("/")
        if len(path_parts) != 4:
            return False
        owner, repo, resource, issue_number = path_parts
        # owner and repo: explicit empty check; resource: validated via equality;
        # issue_number: validated via isdigit() which also rejects empty strings.
        if not owner or not repo:
            return False
        if resource != "issues" or not issue_number.isdigit():
            return False
        return True
    except Exception:
        return False


def is_valid_mcp_server_url(url: str) -> bool:
    """
    Validates that the provided MCP server URL is safe from SSRF.

    Enforces http/https scheme and blocks known cloud metadata hostnames/IPs.

    Args:
        url: The URL string to validate.

    Returns:
        True if the URL is valid and safe, False otherwise.
    """
    blocked_hostnames = {
        "169.254.169.254",
        "metadata.google.internal",
        "169.254.169.253",
        "100.100.100.200",
    }

    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme not in ("http", "https"):
            return False
        if not parsed.hostname:
            return False
        if parsed.hostname.lower() in blocked_hostnames:
            return False
        return True
    except Exception:
        return False
