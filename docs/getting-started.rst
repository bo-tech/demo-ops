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


Configuration
=============

Edit a host config in ``nixos/hosts/`` — set the IP address, gateway,
network interface, and your SSH public key. Then adjust the matching
ansible inventory file in ``ansible/``.

For headless VMs, set ``serialConsole = true`` in the host config.

.. note::

   If you add new files, make sure to add them to git, otherwise they
   will be missing from the flake.

Commit the configuration changes:

.. code-block:: bash

   git add nixos/hosts/ ansible/
   git commit -m "Configure host for my environment"


Secrets
=======

Generate age keypairs, SOPS config, and encrypted secret files:

.. code-block:: bash

   ./scripts/bootstrap-secrets.sh

This creates ``.secrets/`` (gitignored) with two age keys, writes
``.sops.yaml``, and encrypts all secret templates under
``kubernetes/cluster-demo/``.

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
