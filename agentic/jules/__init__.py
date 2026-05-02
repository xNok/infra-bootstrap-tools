"""
Jules agent module for GitHub issue automation.

This module provides the Jules agent for automating GitHub issue assignments
via the MCP server.
"""

from .agent import main as run_agent
from .models import (
    CreateSessionRequest,
    GithubRepo,
    GithubRepoContext,
    Session,
    Source,
    SourceContext,
)

__all__ = [
    "run_agent",
    "GithubRepo",
    "Source",
    "Session",
    "CreateSessionRequest",
    "SourceContext",
    "GithubRepoContext",
]
