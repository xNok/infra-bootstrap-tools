# METADATA
# title: No Multiline Inline Scripts
# description: Denies GitHub Actions steps that contain a newline in their `run` command, ensuring scripts are extracted to dedicated files in the `bin/ci` directory.
package main

import rego.v1

# Deny any run step that contains a newline, suggesting it is a multiline inline script
deny contains msg if {
	some job_id, job in input.jobs
	some step_index, step in job.steps
	step.run
	contains(step.run, "\n")
	step_name := object.get(step, "name", sprintf("step %v", [step_index]))
	msg := sprintf("Job '%v' step '%v' contains a multiline inline script. Please extract this into a dedicated script in the `bin/ci` directory.", [job_id, step_name])
}

