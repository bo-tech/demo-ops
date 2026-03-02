# demo-ops

Example deployment showing how to consume
[business-operations](https://codeberg.org/business-operations/business-operations).

This repository defines a minimal single-node k0s cluster, covering
NixOS deployment and cluster bootstrap with Cilium and OpenEBS.


## Status - Experimental

This is an early example. Application layers are not yet included.


## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- A machine reachable via SSH (bare-metal, cloud VM, or local QEMU/UTM VM)
- Ideally the machine can claim multiple ip addresses

Clone including the submodule:

```sh
git clone --recurse-submodules \
  https://codeberg.org/business-operations/demo-ops.git
```


## Configuration

Edit a host config in `nixos/hosts/` — set the IP address, gateway,
network interface, and your SSH public key. Then adjust the matching
ansible inventory file in `ansible/`.

For headless VMs, set `serialConsole = true` in the host config.

Note: If you add new files, make sure to add them to git, otherwise they will be
missing from the flake.


## Deployment

Deploy NixOS via `nixos-anywhere`. Make sure to adjust the example IP address in
the following command:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake '.#demo-single-node' \
  --target-host root@192.0.2.10
```

Bootstrap the cluster:

```sh
nix develop ./external/business-operations#ansible

# You may have to refresh the host keys
ansible-playbook -i ./ansible/inventory-single-node.yaml \
  $BO_PLAYBOOKS/refresh-ssh-host-keys.yaml

# Prepare the cluster base
ansible-playbook -i ./ansible/inventory-single-node.yaml \
  $BO_PLAYBOOKS/bootstrap-existing-machines.yaml
```

For aarch64 VMs use the `-aarch64` inventory and flake config
variants (e.g. `demo-single-node-aarch64`).


## Useful Commands

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
