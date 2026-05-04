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


def is_safe_mcp_url(url: str) -> bool:
    """
    Validates that the provided MCP URL is safe to use, mitigating SSRF risks.

    Ensures the URL scheme is HTTP/HTTPS and blocks known cloud metadata
    IP addresses and hostnames.

    Args:
        url: The MCP server URL string to validate.

    Returns:
        True if the URL is deemed safe, False otherwise.
    """
    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme not in ("http", "https"):
            return False

        hostname = parsed.hostname
        if not hostname:
            return False

        # Block known metadata IP addresses and hostnames
        forbidden_hosts = {
            "169.254.169.254",  # AWS / GCP / Azure metadata
            "metadata.google.internal",  # GCP metadata
            "169.254.170.2",  # AWS ECS metadata
            "100.100.100.200",  # Alibaba Cloud metadata
        }

        if hostname in forbidden_hosts:
            return False

        return True
    except Exception:
        return False
