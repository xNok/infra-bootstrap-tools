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

# Deny top-level write permissions: top-level should be read-only (e.g. contents: read) and jobs should raise permissions.
deny contains msg if {
	is_object(input.permissions)
	some scope, perm in input.permissions
	perm == "write"
	msg := sprintf("Top-level permission '%v: write' violates least privilege. Top-level permissions must be restricted to read (e.g. 'contents: read'), and individual jobs should raise permissions only where needed.", [scope])
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
