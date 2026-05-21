"""
URL validation utilities for Jules agent.

Centralizes security-sensitive URL validation to prevent prompt injection
and SSRF attacks when processing external user inputs.
"""

import ipaddress
import socket
import urllib.parse


def is_safe_mcp_url(url: str) -> bool:
    """
    Validates an MCP server URL to prevent SSRF vulnerabilities.

    Ensures the URL uses http or https, explicitly blocks known cloud metadata
    hostnames, and verifies that the resolved IP address is not a link-local
    or known metadata IP (e.g., 169.254.169.254, fd00:ec2::254).
    """
    try:
        parsed = urllib.parse.urlparse(url)
        if parsed.scheme not in ("http", "https"):
            return False

        hostname = parsed.hostname
        if not hostname:
            return False

        # Strip brackets for IPv6 addresses
        hostname = hostname.strip("[]")

        # Explicitly block known metadata hostnames
        if hostname.lower() in ["metadata.google.internal", "169.254.169.254"]:
            return False

        # Resolve hostname to check for DNS rebinding/decimal/octal encodings bypasses
        addr_info = socket.getaddrinfo(hostname, None)

        for info in addr_info:
            ip_str = info[4][0]
            ip_obj = ipaddress.ip_address(ip_str)

            # Block link-local addresses
            if ip_obj.is_link_local:
                return False

            # Explicitly block common cloud metadata IPs
            if str(ip_obj) == "169.254.169.254" or str(ip_obj) == "fd00:ec2::254":
                return False

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
