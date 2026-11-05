#!/usr/bin/env bats

@test "nix builds kubeztl package derivation successfully" {
  run nix build .#kubeztl --no-link
  [ "$status" -eq 0 ]
}

@test "kubeztl runs and reports help successfully" {
  run nix run .#kubeztl -- --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "kubectl controls the Kubernetes cluster manager" ]]
}
