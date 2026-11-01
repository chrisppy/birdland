# SPDX-License-Identifier: GPL-3.0-only
{
  description = "Quickshell desktop shell for Niri";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    base24-themes = {
      url = "github:chrisppy/base24-themes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.devfmt.follows = "devfmt";
    };
    devfmt = {
      url = "github:chrisppy/devfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qml-niri = {
      url = "github:imiric/qml-niri/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
      # Share devfmt's copies instead of locking a second set.
      inputs.flake-parts.follows = "devfmt/flake-parts";
      inputs.treefmt-nix.follows = "devfmt/treefmt-nix";
    };
  };

  outputs =
    inputs:
    inputs.devfmt.lib.mkFlake { inherit inputs; } {
      imports = [
        (inputs.devfmt.lib.importTree ./nix)
      ];
    };
}
