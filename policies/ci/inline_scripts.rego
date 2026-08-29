# METADATA
# title: CI Policies
# description: Policies enforcing CI/CD conventions and best practices.
# scope: package
package main

import rego.v1

# METADATA
# title: Prevent Multiline Inline Scripts
# description: Denies any run step that contains a newline, suggesting it is a multiline inline script. All multi-line scripts should be extracted to dedicated files.
# scope: rule
deny contains msg if {
  # Match all jobs in the workflow
  some job_id
  job := input.jobs[job_id]

  # Match all steps in the job
  some step_index
  step := job.steps[step_index]

  # Check if the step has a "run" command
  step.run

  # If the run command contains a newline, it's a multiline script
  contains(step.run, "\n")

  # Generate the error message
  step_name := object.get(step, "name", sprintf("step %v", [step_index]))
  msg := sprintf("Job '%v' step '%v' contains a multiline inline script. Please extract this into a dedicated script in the `bin/ci` directory.", [job_id, step_name])
}
