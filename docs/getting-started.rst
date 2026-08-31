================
Getting Started
================

This guide walks through deploying demo-ops from scratch.


Prerequisites
=============

- `Nix <https://nixos.org/>`_ with flakes enabled
- ``age-keygen`` and ``sops`` available
- A machine reachable via SSH (bare-metal, cloud VM, or local QEMU/UTM VM)
- Ideally the machine can claim multiple IP addresses

For running a local QEMU VM, see :doc:`run-qemu-vm`.
For deploying as a microVM on an existing NixOS host, see
:doc:`run-microvm`.


Clone the repository
====================

Clone including the submodule:

.. code-block:: bash

   git clone --recurse-submodules \
     https://codeberg.org/business-operations/demo-ops.git

Create a working branch for your customizations:

.. code-block:: bash

   cd demo-ops
   git checkout -b my-deployment


.. _sec-getting-started-configuration:

Configuration
=============

Edit a host config in ``nixos/hosts/`` — set the IP address, gateway,
and your SSH public key. Then adjust the matching ansible inventory
file in ``ansible/``.

For headless VMs, set ``serialConsole = true`` in the host config.

Then set the load balancer addresses in
``kubernetes/cluster-demo/flux/vars/cluster-settings.yaml``. The two
Cilium pools, ``cilium_static_pool_cidr`` and ``cilium_pool_cidr``,
must lie inside the machine's own subnet, and so must
``cluster_ingress_ip``, which is handed out from the static pool.
Cilium announces these addresses by answering ARP on the machine's
link, and a client only sends an ARP request for an address it
considers on-link, so a pool outside the subnet is announced to
nobody. Choose blocks that collide neither with the machine itself nor
with what the network hands out over DHCP.

.. note::

   If you add new files, make sure to add them to git, otherwise they
   will be missing from the flake.

Commit the configuration changes:

.. code-block:: bash

   git add nixos/hosts/ ansible/ kubernetes/cluster-demo/flux/vars/
   git commit -m "Configure host for my environment"


Secrets
=======

Generate age keypairs, SOPS config, and encrypted secret files:

.. code-block:: bash

   ./scripts/bootstrap-secrets.sh

This creates ``.secrets/`` (gitignored) with two age keys, writes
``.sops.yaml``, and encrypts the secret templates of every cluster
under ``kubernetes/``. Each cluster gets its own credentials.
Re-running the script leaves a cluster that already has its secrets
alone, so adding a cluster does not disturb one already deployed.

Then export the path to the age key, so that ``sops`` uses it:

.. code-block:: bash

   export SOPS_AGE_KEY_FILE="${PWD}/.secrets/age-user.key"

Make sure to add the ``*.sops.yaml`` files into the git repository:

.. code-block:: bash

   git add .sops.yaml kubernetes
   git commit -m "Add generated secrets"


Deployment
==========

Deploy NixOS via ``nixos-anywhere``. Make sure to adjust the example IP
address in the following command:

.. code-block:: bash

   nix run github:nix-community/nixos-anywhere -- \
     --flake '.#demo-single-node' \
     --target-host root@192.0.2.10

Bootstrap the cluster:

.. code-block:: bash

   nix develop ./external/business-operations#ansible

   # You may have to refresh the host keys
   ansible-playbook -i ./ansible/inventory-single-node.yaml \
     $BO_PLAYBOOKS/refresh-ssh-host-keys.yaml

   # Prepare the cluster base
   ansible-playbook -i ./ansible/inventory-single-node.yaml \
     $BO_PLAYBOOKS/bootstrap-existing-machines.yaml

For aarch64 VMs use the ``-aarch64`` inventory and flake config
variants (e.g. ``demo-single-node-aarch64``).


Result
======

You should have a cluster up and running, and a FluxCD setup in there
without anything being yet installed.

See :doc:`first-login` for accessing the deployed applications.
