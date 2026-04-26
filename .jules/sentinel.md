## 2025-04-26 - Prevent Stack Trace Leaks
**Vulnerability:** Found `traceback.print_exc()` being used in `agentic/deployment/deploy.py` to catch deployment exceptions.
**Learning:** This exposes internal application details and logic on standard output or logs.
**Prevention:** Always log or print a user-friendly error message or `str(e)` without exposing stack traces unless in strict debug mode. Use proper exception logging features instead of directly writing the traceback.
