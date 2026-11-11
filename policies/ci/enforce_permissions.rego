package main

import rego.v1

# Deny workflows with no top-level permissions and jobs lacking explicit permissions
deny contains msg if {
	# Check if top-level permissions are omitted or null
	not input.permissions

	# Check if any job in the workflow lacks permissions
	some job_id, job in input.jobs
	not job.permissions

	msg := sprintf("Workflow does not declare top-level 'permissions', and job '%v' is missing explicit permissions. Follow least-privilege principles.", [job_id])
}

# Deny broad write-all permissions
deny contains msg if {
	input.permissions == "write-all"
	msg := "Workflow declares overly broad 'permissions: write-all'. Specify explicit permission scopes instead."
}

deny contains msg if {
	some job_id, job in input.jobs
	job.permissions == "write-all"
	msg := sprintf("Job '%v' declares overly broad 'permissions: write-all'. Specify explicit permission scopes instead.", [job_id])
}
