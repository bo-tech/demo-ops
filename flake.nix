{
  description = "demo-ops – example deployment using business-operations";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.k0s-nix.url = "github:johbo/k0s-nix";
  inputs.k0s-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  inputs.business-operations.url =
    "git+https://codeberg.org/business-operations/business-operations";

  outputs = {
    self,
    business-operations,
    disko,
    k0s-nix,
    nixpkgs,
  }: let
    sharedModules = [
      business-operations.nixosModules.profile-k0s-node
      business-operations.nixosModules.business-operations
      disko.nixosModules.disko
      k0s-nix.nixosModules.default
      ./nixos/machine-classes/k0s-node-vm-disks.nix
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
    };
  };
}
