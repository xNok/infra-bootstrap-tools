let
  nixpkgs = import <nixpkgs> {
    config = (import ./common.nix { pkgs = nixpkgs; }).nixpkgsConfig;
  };
  common = import ./common.nix { pkgs = nixpkgs; };
in

nixpkgs.mkShell {
  inherit (common) buildInputs shellHook;
}