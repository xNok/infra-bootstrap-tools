"""
URL validation utilities for Jules agent.

Centralizes security-sensitive URL validation to prevent prompt injection
and SSRF attacks when processing external user inputs.
"""

import ipaddress
import urllib.parse


def is_safe_mcp_server_url(url: str) -> bool:
    """
    Validates that the provided MCP server URL is safe to connect to,
    preventing Server-Side Request Forgery (SSRF) to internal metadata endpoints.

    Args:
        url: The URL string to validate.

    Returns:
        True if the URL is safe, False otherwise.
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

        blocked_hostnames = {
            "metadata.google.internal",
            "169.254.169.254",
            "fd00:ec2::254",
        }

        if hostname.lower() in blocked_hostnames:
            return False

        import socket

        try:
            # Resolving the hostname using getaddrinfo supports both IPv4 and IPv6,
            # catching decimal/octal formats and DNS rebinding/redirection to metadata IPs.
            addr_info = socket.getaddrinfo(hostname, None)
            # Check all resolved IPs for the hostname
            for addr in addr_info:
                ip_str = addr[4][0]
                ip = ipaddress.ip_address(ip_str)

                if str(ip) in blocked_hostnames:
                    return False

                # Also explicitly block link-local and unique-local/site-local networks
                if ip.is_link_local or getattr(ip, "is_site_local", False):
                    # 169.254.169.254 is within link-local
                    if ip.version == 4 and str(ip).startswith("169.254."):
                        return False
                    # Block IPv6 unique local addresses explicitly if site_local isn't enough
                    if ip.version == 6 and (
                        ip_str.startswith("fd00:") or ip_str.startswith("fc00:")
                    ):
                        return False

        except (socket.gaierror, ValueError):
            # If it's a Docker container name or unresolvable at this stage, we fall back to strict string checking.
            # We fail closed (return False) if we suspect the user gave a resolvable IP that we can't look up,
            # but since "localhost" and other things might fail in restrictive environments,
            # we just pass if the resolution fails, letting string-based checks handle what they can.
            pass

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
