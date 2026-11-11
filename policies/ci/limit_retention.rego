package main

import rego.v1

deny contains msg if {
	some job_id, job in input.jobs
	some step_index, step in job.steps
	uses_action := object.get(step, "uses", "")
	startswith(uses_action, "actions/upload-artifact")

	with_block := object.get(step, "with", {})
	not with_block["retention-days"]

	step_name := object.get(step, "name", sprintf("step %v", [step_index]))
	msg := sprintf("Job '%v' step '%v' uses 'actions/upload-artifact' without setting explicit 'retention-days'. Defaulting to 90 days wastes storage resources.", [job_id, step_name])
}
