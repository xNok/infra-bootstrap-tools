# METADATA
# title: Action SHAs Pinned
# description: Denies GitHub Actions steps and jobs that do not pin third-party actions to a full 40-character commit SHA.
package pinned_actions

import rego.v1

deny contains msg if {
  some job_id
  job := input.jobs[job_id]

  some step_index
  step := job.steps[step_index]

  step.uses
  not startswith(step.uses, "./")
  not startswith(step.uses, "docker://")

  parts := split(step.uses, "@")
  count(parts) == 2
  version := parts[1]

  version_parts := split(version, " ")
  sha := version_parts[0]

  not regex.match("^[a-fA-F0-9]{40}$", sha)

  step_name := object.get(step, "name", sprintf("step %v", [step_index]))
  msg := sprintf("Job '%v' step '%v' uses an unpinned action '%v'. Third-party actions must be pinned to a full commit SHA.", [job_id, step_name, step.uses])
}

deny contains msg if {
  some job_id
  job := input.jobs[job_id]

  job.uses
  not startswith(job.uses, "./")

  parts := split(job.uses, "@")
  count(parts) == 2
  version := parts[1]

  version_parts := split(version, " ")
  sha := version_parts[0]

  not regex.match("^[a-fA-F0-9]{40}$", sha)

  msg := sprintf("Job '%v' uses an unpinned reusable workflow '%v'. Third-party workflows must be pinned to a full commit SHA.", [job_id, job.uses])
}
