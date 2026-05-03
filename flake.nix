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
        # Dynamically create shell endpoints (`nix develop .#<name>`)
        # by mapping over the configurations defined in our common.nix file.
        # This keeps our flake.nix extremely clean.
        devShells = pkgs.lib.mapAttrs (_: shell: pkgs.mkShell shell) common.shells;

        packages = pkgs.lib.mapAttrs (name: shell:
          pkgs.buildEnv {
            name = "ibt-${name}";
            paths = shell.buildInputs;
            ignoreCollisions = true;
          }
        ) common.shells;
      }
    );
}
