{
  description = "virtual environments";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.11";
    flake-utils.url = "github:numtide/flake-utils";
    emacs.url = "github:nix-community/emacs-overlay";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.flake-utils.follows = "flake-utils";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    emacs-ci.url = "github:sigma/nix-emacs-ci";
    emacs-ci.inputs.flake-utils.follows = "flake-utils";
    emacs-ci.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, devshell, emacs, emacs-ci, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          emacs.overlay
          emacs-ci.overlay
          devshell.overlay
        ];
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays ++ [
            # fallback to x86_64 for Emacs versions that don't build on ARM. Rosetta will handle them.
            (final: prev: (nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
              inherit (import nixpkgs {system = "x86_64-darwin"; overlays = overlays;})
                emacs-25-1 emacs-25-2 emacs-25-3
                emacs-26-1 emacs-26-2 emacs-26-3
                emacs-27-1 emacs-27-2;
            }))
          ];
        };
        multiEmacs = {flavors, wrapper ? (x: x)}: pkgs.runCommandLocal "combined-emacs" {} (
          nixpkgs.lib.strings.concatStrings ([
            "mkdir -p $out/bin; "
          ] ++ (map (f: "ln -s ${(wrapper f)}/bin/emacs $out/bin/emacs-${f.version}; ") flavors)));

      in
        {
          devShell =
            pkgs.devshell.mkShell {
              packages = [(multiEmacs {flavors = [pkgs.emacs-snapshot];})];
            };

          packages = {
            inherit (pkgs)
              emacs-25-1 emacs-25-2 emacs-25-3
              emacs-26-1 emacs-26-2 emacs-26-3
              emacs-27-1 emacs-27-2
              emacs-snapshot;
          };

          lib = {
            inherit multiEmacs;
            inherit (pkgs)
              emacsWithPackages
              emacsWithPackagesFromPackageRequires
              emacsWithPackagesFromUsePackage;
          };
        });
}
