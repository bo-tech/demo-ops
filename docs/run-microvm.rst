====================
 Running a MicroVM
====================

This guide walks through deploying demo-ops as a microVM on an existing
NixOS host using `microvm.nix
<https://github.com/microvm-nix/microvm.nix>`_.
This is an alternative to the :doc:`QEMU approach <run-qemu-vm>` and
is useful when you already have a NixOS machine with spare capacity.
For a cluster that survives losing a node, see
:doc:`run-three-node-microvm`.


Prerequisites
=============

- Nix installed on your workstation
- A NixOS host prepared for microVMs — see
  :doc:`bo:kubernetes/microvm` for the required modules and host setup


Configuration
=============

Edit ``nixos/hosts/demo-single-node-microvm.nix``:

- Set the IP address and gateway for your network
- Set ``network.prefixLength`` if your subnet is not ``/24``
- Add your SSH public key
- Adjust the MAC address if needed

Edit ``ansible/inventory-microvm.yaml``:

- Set ``ansible_host`` to match the VM IP
- Set ``microvm_host`` to the hypervisor's IP

The guest attaches to the hypervisor's bridge, so it lands on whatever
network that host's NIC is on rather than on one of its own. Set the
load balancer addresses to match, as
:ref:`sec-getting-started-configuration` describes — the Cilium pools have
to lie inside the guest's subnet, and it is this path where that subnet
is most easily not the one you expected.


Deployment
==========

Enter the ansible development shell:

.. code-block:: bash

   nix develop ./external/business-operations#ansible

Export the path to the age key. ``bootstrap-cluster.yaml`` decrypts a
SOPS file, and fails at that step without it:

.. code-block:: bash

   export SOPS_AGE_KEY_FILE="${PWD}/.secrets/age-user.key"

Deploy the microVM to the hypervisor host:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-microvm.yaml \
     $BO_PLAYBOOKS/deploy-microvms.yaml

This builds the NixOS configuration, installs it on the hypervisor,
creates the volumes, and starts the VM.

Verify SSH access:

.. code-block:: bash

   ssh root@<vm-ip> hostname

Bootstrap the Kubernetes cluster:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-microvm.yaml \
     $BO_PLAYBOOKS/bootstrap-existing-machines.yaml

Kick off FluxCD:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-microvm.yaml \
     $BO_PLAYBOOKS/bootstrap-cluster.yaml


Result
======

You should have a single-node Kubernetes cluster running inside a
microVM, with Flux managing the applications.

See :doc:`first-login` for accessing the deployed applications.


Without a cluster
=================

``dev-microvm`` and ``ansible/inventory-dev-microvm.yaml`` are the same
setup with the application layer left off. The inventory sets
``skip_rook_ceph`` and declares no ``cluster_path``, so
``bootstrap-existing-machines.yaml`` stops once Cilium and OpenEBS are
in and there is no Flux step to run.

Deploy it exactly as above, substituting the inventory. It is the
cheaper way to check that a change to the NixOS layer or to the flake
inputs still produces a machine that boots and joins a cluster.
