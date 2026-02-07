{
  description = "demo-ops – example deployment using business-operations";

  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.k0s-nix.url = "github:johbo/k0s-nix";
  inputs.k0s-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  inputs.business-operations.url =
    "github:bo-tech/business-operations";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.deploy-keys = {
    url = "path:./deploy-keys";
    flake = false;
  };

  outputs = {
    self,
    business-operations,
    deploy-keys,
    disko,
    flake-utils,
    k0s-nix,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};

        generate-secrets = pkgs.writeShellScriptBin "generate-secrets" ''
          set -euo pipefail
          secrets_dir=".secrets"
          deploy_keys_dir="deploy-keys"

          mkdir -p "$secrets_dir"
          chmod 0700 "$secrets_dir"

          if [ -f "$deploy_keys_dir/ssh_key.pub" ]; then
            echo "Keys already exist, skipping."
            exit 0
          fi

          ${pkgs.openssh}/bin/ssh-keygen \
            -t ed25519 -N "" -f "$secrets_dir/ssh_key"
          chmod 0600 "$secrets_dir/ssh_key" "$secrets_dir/ssh_key.pub"
          cp "$secrets_dir/ssh_key.pub" "$deploy_keys_dir/ssh_key.pub"
          echo "Generated SSH key pair in $secrets_dir/"
          echo "Public key copied to $deploy_keys_dir/ for deployment."
        '';
      in {
        apps.generate-secrets = {
          type = "app";
          program = "${generate-secrets}/bin/generate-secrets";
        };
      }
    )
    // {
      nixosConfigurations = let
        sshPubKey =
          builtins.readFile "${deploy-keys}/ssh_key.pub";

        sharedModules = [
          business-operations.nixosModules.profile-k0s-node
          disko.nixosModules.disko
          k0s-nix.nixosModules.default
          ./nixos/machine-classes/k0s-node-vm-disks.nix
        ];
      in {
        demo-single-node = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit sshPubKey;};
          modules =
            [
              self.nixosModules.nixpkgs-config
              ./nixos/hardware/vm/qemu.nix
              ./nixos/hosts/demo-single-node.nix
            ]
            ++ sharedModules;
        };

        demo-single-node-aarch64 = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit sshPubKey;};
          modules =
            [
              self.nixosModules.nixpkgs-config-aarch64
              ./nixos/hardware/vm/qemu.nix
              ./nixos/hosts/demo-single-node.nix
            ]
            ++ sharedModules;
        };

        dev = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit sshPubKey;};
          modules =
            [
              self.nixosModules.nixpkgs-config-aarch64
              ./nixos/hardware/vm/qemu.nix
              ./nixos/hosts/dev.nix
            ]
            ++ sharedModules;
        };
      };

      nixosModules = let
        nixpkgs-config-gen = system: {
          nixpkgs.system = system;
          nixpkgs.pkgs = import nixpkgs {
            system = system;
            overlays = [
              k0s-nix.overlays.default
            ];
            config.allowUnfree = true;
          };
        };
      in {
        nixpkgs-config = nixpkgs-config-gen "x86_64-linux";
        nixpkgs-config-aarch64 = nixpkgs-config-gen "aarch64-linux";
      };
    };
}
