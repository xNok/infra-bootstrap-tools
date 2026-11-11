package main

import rego.v1

get_on(doc) := res if {
	res := doc["on"]
} else := res if {
	res := doc[true]
} else := res if {
	res := doc["true"]
} else := null

# Helper to check if workflow triggers on pull_request
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

# Deny PR workflows missing concurrency
deny contains msg if {
	is_pr_workflow
	not input.concurrency
	msg := "Workflow triggers on 'pull_request' but has no 'concurrency' group configured. Add concurrency with 'cancel-in-progress: true' (or conditional on PRs) to save runner minutes."
}

# Deny PR workflows that hardcode cancel-in-progress: false
deny contains msg if {
	is_pr_workflow
	input.concurrency["cancel-in-progress"] == false
	msg := "Workflow triggers on 'pull_request' with hardcoded 'cancel-in-progress: false'. Obsolete commits will run to completion and waste runner minutes. Enable 'cancel-in-progress: true' or '${{ github.ref != \\'refs/heads/main\\' }}'."
}
