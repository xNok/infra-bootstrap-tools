package main

deny[msg] {
  step := input.jobs[_].steps[_]
  contains(step.run, "\n")
  msg = sprintf("Inline multi-line scripts are not allowed. Move the script to bin/ci and run it as a single line. Found in step: %v", [step.name])
}
