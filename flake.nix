{
  description = "demo-ops – example deployment using business-operations";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.k0s-nix.url = "github:nix-community/k0s-nix";
  inputs.k0s-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  inputs.business-operations.url =
    "git+https://codeberg.org/business-operations/business-operations";
  inputs.business-operations.inputs.nixpkgs.follows = "nixpkgs";

  inputs.microvm.url = "github:microvm-nix/microvm.nix";
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
      business-operations.nixosModules.cache-proxy
      disko.nixosModules.disko
      k0s-nix.nixosModules.default
      ./nixos/machine-classes/k0s-node-vm-disks.nix
    ];

    microvmSharedModules = [
      business-operations.nixosModules.profile-k0s-node
      business-operations.nixosModules.business-operations
      business-operations.nixosModules.cache-proxy
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

    demoNodes = import ./nixos/hosts/demo-nodes.nix;

    demoNodeConfigurations = nixpkgs.lib.listToAttrs (
      map (node: {
        name = "demo-node-${node.index}-microvm";
        value = mkMicrovmHost {
          hostModule = import ./nixos/profiles/demo-node-microvm.nix node;
        };
      }) demoNodes
    );
  in {
    nixosConfigurations = demoNodeConfigurations // {
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

      demo-single-node-microvm = mkMicrovmHost {
        hostModule = ./nixos/hosts/demo-single-node-microvm.nix;
      };

      dev-microvm = mkMicrovmHost {
        hostModule = ./nixos/hosts/dev-microvm.nix;
      };
    };
  };
}
