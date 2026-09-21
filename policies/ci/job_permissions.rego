# METADATA
# title: Job or Workflow Permissions Enforced
# description: Denies GitHub Actions workflows and jobs that do not specify explicit `permissions` for least-privilege security.
package permissions

import rego.v1

# Deny if a workflow lacks global permissions AND at least one job lacks permissions
deny contains msg if {
  not input.permissions

  some job_id
  job := input.jobs[job_id]
  not job.permissions

  msg := sprintf("Workflow lacks global permissions and Job '%v' lacks explicit 'permissions'. Enforce least-privilege by specifying permissions.", [job_id])
}
