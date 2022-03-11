{
  description = "dev environment";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/21.11;
    flake-utils.url = github:numtide/flake-utils;

    multi-emacs.url = github:sigma/multi-emacs;
    multi-emacs.inputs.nixpkgs.follows = "nixpkgs";
    multi-emacs.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, multi-emacs }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShell =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              multi-emacs.overlay
            ];
          };
        in
          pkgs.devshell.mkShell {
            packages = [
              (pkgs.multiEmacs {
                wrapper = emacs: (pkgs.emacsPackagesFor emacs).emacsWithPackages(epkgs: [
                  # your dependencies here
                ]);
                flavors = [
                  pkgs.emacs
                ];
              })
            ];
          };
    });
}
