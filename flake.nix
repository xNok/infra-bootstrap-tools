{
  description = "Infrastructure Bootstrap Tools - Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = (import ./bin/nix/common.nix { inherit pkgs; }).nixpkgsConfig;
        };
        common = import ./bin/nix/common.nix { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          inherit (common) buildInputs shellHook;
        };
      }
    );
}
