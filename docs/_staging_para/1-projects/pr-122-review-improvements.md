# PR 122 Review Improvements

## Task
Apply changes based on review comments for PR #122 (Docker Secrets implementation for OpenZiti)

## Review Comments to Address

### 1. Security: Remove plaintext password from git (HIGH PRIORITY)
- File: `stacks/openziti/secrets/ziti_admin_password`
- Issue: Plaintext "admin" password committed to repo
- Solution: Create `.example` file, add actual file to .gitignore, update docs

### 2. Consistency: Format entrypoint commands
- File: `stacks/openziti/ziti.local.yaml:24-27`
- Issue: Should use multiline string with pipe operator for consistency with production stack
- Current: Array format with inline command
- Target: Match openziti-stack.yml format (lines 28-32)

### 3. Consistency: Router entrypoint format
- File: `stacks/openziti/ziti.local.yaml:39`
- Issue: Uses inline array `["/bin/bash"]` vs multiline array format
- Target: Use multiline array format

### 4. Error handling: JWT copy operations need logging
- File: `stacks/openziti/ziti.local.yaml:42` (init container)
- File: `stacks/openziti/ziti.local.yaml:90` (router)
- Issue: Silent failure with `2>/dev/null || true`
- Solution: Add logging/warnings when files not found

### 5. Race condition: Router may start before JWT files available
- File: `stacks/openziti/ziti.local.yaml:90`
- Issue: No explicit dependency or wait mechanism for JWT files
- Solution: Add retry loop with timeout (30 attempts, 2s sleep)

### 6. Documentation: Explain enrollment volume architecture
- File: `stacks/openziti/docs/ARCHITECTURE.md`
- Issue: Missing explanation of ziti-enrollment volume purpose
- Solution: Add section explaining JWT transfer mechanism and security benefit

## Implementation Plan

1. ✅ Create staging note (this file)
2. [ ] Fix security issue: Move password to .example file
3. [ ] Update .gitignore
4. [ ] Fix entrypoint consistency issues
5. [ ] Add robust JWT copy operations with logging
6. [ ] Add documentation for enrollment volume
7. [ ] Validate changes
8. [ ] Report progress
