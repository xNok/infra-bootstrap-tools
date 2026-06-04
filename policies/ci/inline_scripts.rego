package main

# Deny any run step that contains a newline, suggesting it is a multiline inline script
deny[msg] {
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
