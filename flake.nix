{
  description = "demo-ops – example deployment using business-operations";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  # TODO: Switch back to main after merging consolidate-unit-name
  inputs.k0s-nix.url = "github:johbo/k0s-nix/consolidate-unit-name";
  inputs.k0s-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  inputs.business-operations.url =
    "git+https://codeberg.org/business-operations/business-operations";

  # TODO: Switch to upstream once merged:
  # - Deploy script platform fix: https://github.com/microvm-nix/microvm.nix/pull/475
  inputs.microvm.url = "github:johbo/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    business-operations,
    disko,
    k0s-nix,
    microvm,
    nixpkgs,
  }: let
    sharedModules = [
      business-operations.nixosModules.profile-k0s-node
      business-operations.nixosModules.business-operations
      disko.nixosModules.disko
      k0s-nix.nixosModules.default
      ./nixos/machine-classes/k0s-node-vm-disks.nix
    ];

    microvmSharedModules = [
      business-operations.nixosModules.profile-k0s-node
      business-operations.nixosModules.business-operations
      business-operations.nixosModules.microvm-guest
      microvm.nixosModules.microvm
      k0s-nix.nixosModules.default
    ];

    nixpkgs-config-gen = system: {
      nixpkgs.system = system;
      nixpkgs.pkgs = import nixpkgs {
        inherit system;
        overlays = [k0s-nix.overlays.default];
        config.allowUnfree = true;
      };
    };

    mkHost = {
      hostModule,
      system ? "x86_64-linux",
    }:
      nixpkgs.lib.nixosSystem {
        modules =
          [
            (nixpkgs-config-gen system)
            ./nixos/hardware/vm/qemu.nix
            hostModule
          ]
          ++ sharedModules;
      };

    mkMicrovmHost = {
      hostModule,
      system ? "x86_64-linux",
    }:
      nixpkgs.lib.nixosSystem {
        modules =
          [
            (nixpkgs-config-gen system)
            hostModule
          ]
          ++ microvmSharedModules;
      };
  in {
    nixosConfigurations = {
      demo-single-node = mkHost {
        hostModule = ./nixos/hosts/demo-single-node.nix;
      };

      demo-single-node-aarch64 = mkHost {
        hostModule = ./nixos/hosts/demo-single-node.nix;
        system = "aarch64-linux";
      };

      dev = mkHost {
        hostModule = ./nixos/hosts/dev.nix;
      };

      dev-aarch64 = mkHost {
        hostModule = ./nixos/hosts/dev.nix;
        system = "aarch64-linux";
      };

      demo-single-node-microvm = mkMicrovmHost {
        hostModule = ./nixos/hosts/demo-single-node-microvm.nix;
      };
    };
  };
}
