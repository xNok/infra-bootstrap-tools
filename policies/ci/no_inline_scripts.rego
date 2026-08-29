package main

import rego.v1

# METADATA
# title: No Inline Scripts
# description: Denies any inline multi-line scripts across all jobs and steps. Scripts must be moved to bin/ci and run as a single line command.
# scope: rule
deny contains msg if {
  step := input.jobs[_].steps[_]
  contains(step.run, "\n")
  msg = sprintf("Inline multi-line scripts are not allowed. Move the script to bin/ci and run it as a single line. Found in step: %v", [step.name])
}
