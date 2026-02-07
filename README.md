# demo-ops

Example deployment showing how to consume
[business-operations](https://github.com/bo-tech/business-operations).

This repository defines a minimal single-node k0s cluster on a QEMU VM,
covering NixOS deployment and cluster formation up to `fetch_kubeconfig`.


## Status - Experimental

This is an early example. Cilium, OpenEBS, and application layers are
not yet included.


## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- ssh public key into `.secrets/deploy-keys/ssh_key.pub`.

Copy your public key or generate a SSH key pair:

```sh
nix run .#generate-secrets
```

Keys are written to `.secrets/` (git-ignored). The public key is
additionally copied to `.secrets/deploy-keys/` for use as a flake
input override during deployment.


## Deployment

Enter the ansible shell from business-operations:

```sh
nix develop github:bo-tech/business-operations#ansible
```

Deploy NixOS and bootstrap the cluster (from the `ansible/` directory):

```sh
cd ansible
ansible-playbook -i ./inventory-single-node.yaml \
  --extra-vars nixos_extra_flags='--override-input deploy-keys path:../.secrets/deploy-keys' \
  $BO_PLAYBOOKS/re-create-machines.yaml
```

For aarch64 VMs use `inventory-single-node-aarch64.yaml` instead.


## Useful Commands

The following commands should help with building or inspecting the setup,
without deploying anything.

Inject public keys with an input override:

```sh
export DEPLOY_KEYS=(--override-input deploy-keys path:./.secrets/deploy-keys)
```

Build the system closure:

```sh
nix build '.#nixosConfigurations.demo-single-node.config.system.build.toplevel' \
  "${DEPLOY_KEYS[@]}"
```

Deploy to a running machine via `nixos-rebuild`:

```sh
nixos-rebuild switch --flake '.#demo-single-node' \
  --target-host root@192.0.2.10 \
  "${DEPLOY_KEYS[@]}"
```

Inspect configuration values:

```sh
# Check which SSH keys will be deployed
nix eval '.#nixosConfigurations.demo-single-node.config.users.users.root.openssh.authorizedKeys.keys' \
  "${DEPLOY_KEYS[@]}"

# Check the hostname
nix eval '.#nixosConfigurations.demo-single-node.config.networking.hostName' \
  "${DEPLOY_KEYS[@]}"
```


## Contact

joh@bo-tech.de
