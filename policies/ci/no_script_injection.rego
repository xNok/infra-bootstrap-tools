package main

import rego.v1

dangerous_patterns := [
	"${{ github.event.issue.title",
	"${{ github.event.issue.body",
	"${{ github.event.pull_request.title",
	"${{ github.event.pull_request.body",
	"${{ github.event.comment.body",
	"${{ github.head_ref",
]

deny contains msg if {
	some job_id, job in input.jobs
	some step_index, step in job.steps
	run_cmd := object.get(step, "run", "")

	some pattern in dangerous_patterns
	contains(run_cmd, pattern)

	step_name := object.get(step, "name", sprintf("step %v", [step_index]))
	msg := sprintf("Job '%v' step '%v' interpolates dangerous expression '%v' directly into run script. Set it as an environment variable in 'env:' instead to prevent shell injection.", [job_id, step_name, pattern])
}
