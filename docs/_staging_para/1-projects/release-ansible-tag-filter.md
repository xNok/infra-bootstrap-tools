# Release Ansible Tag Filter

## Capture
- User reported that `publish-ansible` condition in `.github/workflows/release.yml` is too broad.
- Current condition: `startsWith(github.ref, 'refs/tags/v')`.
- Risk: Any `v*` tag can trigger Ansible publish, even when not intended for Ansible.

## Plan
- Narrow condition to explicit ansible package tag format used by changesets.
- Keep compatible with existing release trigger patterns (`*@*`).

## Change
- Update `publish-ansible.if` to match the exact Ansible collection package tag prefix in `github.ref_name`:
	- starts with `ansible-collection-infra-bootstrap-tools@`

## Validation
- Confirm `publish-agentic` and `publish-stacks` already use package-specific `github.ref_name` checks.
- Ensure `publish-ansible` now follows same package-specific style.
