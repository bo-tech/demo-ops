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
- ssh public key into `deploy-keys/ssh_key.pub`.

Copy your public key or generate a SSH key pair:

```sh
nix run .#generate-secrets
```

Note that the handling of the SSH public key is at best a "hack" at the moment.
Nix flakes will only take files into account which git sees.

## Deployment

Deploy a single machine with nixos-anywhere:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake '.#demo-single-node' \
  --target-host root@192.0.2.10
```

Alternatively, use ansible to deploy and bootstrap the full cluster.

Enter the ansible shell from business-operations:

```sh
nix develop github:bo-tech/business-operations#ansible
```

Deploy NixOS and bootstrap the cluster (from the `ansible/` directory):

```sh
cd ansible
ansible-playbook -i ./inventory-single-node.yaml $BO_PLAYBOOKS/re-create-machines.yaml
```

For aarch64 VMs use `inventory-single-node-aarch64.yaml` instead.


## Useful Commands

Use a local clone of business-operations for development iteration:

```sh
nix flake lock --override-input business-operations path:../business-operations
```

Build the system closure:

```sh
nix build '.#nixosConfigurations.demo-single-node.config.system.build.toplevel'
```

Deploy to a running machine via `nixos-rebuild`:

```sh
nixos-rebuild switch --flake '.#demo-single-node' \
  --target-host root@192.0.2.10
```

Inspect configuration values:

```sh
nix eval '.#nixosConfigurations.demo-single-node.config.networking.hostName'
```


## Known Problems

### kexec hangs on aarch64 VMs (UTM/QEMU on Apple Silicon)

When re-deploying an already installed machine, nixos-anywhere uses kexec to
boot into the NixOS installer. On aarch64 VMs under UTM/QEMU with Apple
Hypervisor.framework, kexec may cause the VM to hang. Possible causes include
missing kernel config, PSCI/CPU enable method mismatches, or HVF not properly
handing off hypervisor state during kexec.

**Workaround:** Boot the VM from the NixOS installer ISO before re-deploying
and skip the kexec phase:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake '.#demo-single-node' \
  --phases disko,install,reboot \
  --target-host root@192.0.2.10
```

When using ansible, set `nixos_anywhere_extra_flags` in your inventory
accordingly.


## Contact

joh@bo-tech.de
