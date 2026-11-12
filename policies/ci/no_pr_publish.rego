package main

import rego.v1

get_on(doc) := res if {
	res := doc["on"]
} else := res if {
	res := doc[true]
} else := res if {
	res := doc["true"]
} else := null

is_pr_workflow if {
	on_config := get_on(input)
	on_config != null
	on_config.pull_request != null
}

is_pr_workflow if {
	on_config := get_on(input)
	is_string(on_config)
	on_config == "pull_request"
}

is_pr_workflow if {
	on_config := get_on(input)
	is_array(on_config)
	"pull_request" in on_config
}

# Check if an "if" expression guards against pull_request events
is_pr_guarded(expr) if {
	is_string(expr)
	contains(expr, "pull_request")
}

is_pr_guarded(expr) if {
	is_string(expr)
	contains(expr, "refs/heads/main")
}

# Deny steps publishing Flux OCI artifacts on pull_request events without guards
deny contains msg if {
	is_pr_workflow
	some job_id, job in input.jobs
	not is_pr_guarded(object.get(job, "if", ""))

	some step_index, step in job.steps
	run_cmd := object.get(step, "run", "")
	contains(run_cmd, "publish-flux-artifact.sh")
	not is_pr_guarded(object.get(step, "if", ""))

	step_name := object.get(step, "name", sprintf("step %v", [step_index]))
	msg := sprintf("Job '%v' step '%v' publishes Flux OCI artifacts during pull_request events without a guard condition.", [job_id, step_name])
}

# Deny jobs with package write permissions on PR events unless guarded
deny contains msg if {
	is_pr_workflow
	some job_id, job in input.jobs
	not is_pr_guarded(object.get(job, "if", ""))

	job_perms := object.get(job, "permissions", object.get(input, "permissions", {}))
	job_perms.packages == "write"

	# If the workflow doesn't explicitly restrict steps or if it has push steps
	some step_index, step in job.steps
	run_cmd := object.get(step, "run", "")
	contains(run_cmd, "publish")
	not is_pr_guarded(object.get(step, "if", ""))

	step_name := object.get(step, "name", sprintf("step %v", [step_index]))
	msg := sprintf("Job '%v' step '%v' has packages:write permission and runs a publish command without checking if event is pull_request.", [job_id, step_name])
}
