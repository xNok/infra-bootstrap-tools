# Traditional nix-shell entrypoint for backward compatibility.
# Allows entering targeted environments: `nix-shell --argstr shell ansible bin/nix/shell.nix`
# If no argument is provided, it defaults to the "default" shell.
{ shell ? "default" }:

let
  nixpkgs = import <nixpkgs> {
    config = (import ./common.nix { pkgs = nixpkgs; }).nixpkgsConfig;
  };
  common = import ./common.nix { pkgs = nixpkgs; };
in

nixpkgs.mkShell common.shells.${shell}