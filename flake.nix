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
    let
      composeOverlays = overlays: final: prev:
        nixpkgs.lib.foldl' (nixpkgs.lib.flip nixpkgs.lib.extends) (nixpkgs.lib.const prev) overlays final;
      overlay = composeOverlays [
        emacs.overlay
        emacs-ci.overlay
        devshell.overlay
        # fallback to x86_64 for Emacs versions that don't build on ARM. Rosetta will handle them.
        (final: prev: (nixpkgs.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
          inherit (import nixpkgs {system = "x86_64-darwin"; overlays = [overlay];})
            emacs-25-1 emacs-25-2 emacs-25-3
            emacs-26-1 emacs-26-2 emacs-26-3
            emacs-27-1 emacs-27-2;
        }))
        # export multiEmacs facility
        (final: prev: {
          multiEmacs = {
            flavors,
              wrapper ? (x: x),
          }: prev.runCommandLocal "combined-emacs" {} (
            nixpkgs.lib.strings.concatStrings ([
              "mkdir -p $out/bin; "
            ] ++ (map (f: "ln -s ${(wrapper f)}/bin/emacs $out/bin/emacs-${f.version}; ") flavors)));
        })
      ];
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [overlay];
          };
        in
          {
            devShell =
              pkgs.devshell.mkShell {
                packages = [(pkgs.multiEmacs {
                  flavors = [pkgs.emacs-snapshot];
                })];
              };
          }) // {
            overlay = overlay;
          };
}
