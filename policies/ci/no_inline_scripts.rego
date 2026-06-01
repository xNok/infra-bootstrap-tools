package main

deny[msg] {
  step := input.jobs[_].steps[_]
  step.run
  run_script := trim_space(step.run)
  contains(run_script, "\n")
  msg = sprintf("Inline scripts are not allowed. Please move the script to bin/ci/. Found in step: %v", [step.name])
}
