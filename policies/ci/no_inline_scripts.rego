package main

import future.keywords.in

deny[msg] {
    some job in input.jobs
    some step in job.steps
    step.run
    contains(step.run, "\n")
    msg := sprintf("Inline scripts are not allowed. Found in step '%v'. Extract this to a script in bin/ci/.", [step.name])
}
