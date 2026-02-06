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

Generate an SSH key pair (used by NixOS to authorize access):

```sh
nix run .#generate-secrets
```

Keys are written to `.secrets/` (git-ignored).


## Deployment

Enter the ansible shell from business-operations:

```sh
nix develop github:bo-tech/business-operations#ansible
```

Deploy NixOS and bootstrap the cluster (from the `ansible/` directory):

```sh
cd ansible
ansible-playbook -i ./inventory-single-node.yaml \
  $BO_PLAYBOOKS/re-create-machines.yaml
```

For aarch64 VMs use `inventory-single-node-aarch64.yaml` instead.


## Contact

joh@bo-tech.de
