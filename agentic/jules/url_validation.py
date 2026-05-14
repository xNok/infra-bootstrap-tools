"""
URL validation utilities for Jules agent.

Centralizes security-sensitive URL validation to prevent prompt injection
and SSRF attacks when processing external user inputs.
"""

import urllib.parse


def is_safe_mcp_server_url(url: str) -> bool:
    """
    Validates that the provided MCP server URL is safe from SSRF attacks.

    Ensures the scheme is http or https and explicitly blocks known
    cloud metadata IP addresses and hostnames.

    Args:
        url: The URL string to validate.

    Returns:
        True if the URL appears safe, False otherwise.
    """
    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme not in ["http", "https"]:
            return False

        hostname = parsed.hostname
        if not hostname:
            return False

        # Block cloud metadata endpoints
        blocked_hostnames = {
            "169.254.169.254",  # AWS, GCP, Azure metadata IP
            "fd00:ec2::254",  # AWS IPv6 metadata (urllib.parse strips brackets)
            "metadata.google.internal",  # GCP metadata
            "100.100.100.200",  # Alibaba Cloud metadata
        }

        # Exact match or IP-based block
        if hostname in blocked_hostnames:
            return False

        # Consider blocking localhost if this is deployed remotely,
        # but the README suggests localhost is used for MCP server.

        return True
    except Exception:
        return False


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
