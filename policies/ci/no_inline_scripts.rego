package ci.no_inline_scripts

deny[msg] {
    some job_id
    job := input.jobs[job_id]
    some step_id
    step := job.steps[step_id]

    run_script := step.run

    # Check if the run block contains a newline (is multi-line)
    contains(run_script, "\n")

    step_name := object.get(step, "name", sprintf("step %v", [step_id]))
    msg := sprintf("Job '%v' step '%v' contains a multi-line inline script. Avoid inline scripts in CI, use script files in bin/ci instead.", [job_id, step_name])
}
