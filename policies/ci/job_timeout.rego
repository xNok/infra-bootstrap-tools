# METADATA
# title: Job Timeout Enforced
# description: Denies GitHub Actions jobs that do not specify an explicit `timeout-minutes` to prevent runaway executions.
package timeout

import rego.v1

# Deny any job that is missing the timeout-minutes property
deny contains msg if {
  some job_id
  job := input.jobs[job_id]

  # Exclude reusable workflows since they do not support timeout-minutes on the caller job
  not job.uses

  # Check if the job lacks timeout-minutes
  not job["timeout-minutes"]

  msg := sprintf("Job '%v' is missing the 'timeout-minutes' property. All jobs must have explicit timeouts.", [job_id])
}
