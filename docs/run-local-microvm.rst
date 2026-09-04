======================================
 Running a MicroVM on your workstation
======================================

This guide deploys demo-ops as a microVM on the machine you work on,
rather than on a separate hypervisor host. It is the same microVM path
as :doc:`run-microvm`, with the workstation acting as its own
hypervisor.

Use it when you want a cluster to develop against without occupying
another machine, and especially when your workstation is on wifi ---
see `Why the guest is routed`_ below.


Prerequisites
=============

- A NixOS workstation with KVM
- The ``microvm.nix`` host modules enabled on it
- A bridge named ``br0`` with **no physical interface** attached, an
  address on it, and NAT from that bridge out through the machine's
  own network interface
- SSH access to ``root`` on the workstation itself

:doc:`bo:kubernetes/microvm` covers the host modules. The bridge
differs from the setup described there: it takes no uplink.


Why the guest is routed
=======================

The microVM setup for a hypervisor host puts the guest directly on the
LAN by making the host's physical interface a port of ``br0``. A
workstation on wifi cannot do that. 802.11 associates one MAC address
per station, and an infrastructure-mode frame has no field for a
sender behind that station, so a bridged guest's frames are never
carried and nothing routes back to it.

Giving ``br0`` no uplink and masquerading its traffic avoids the
problem entirely. Only the workstation's own MAC ever appears on the
network, and the guest reaches the outside through it. The guest is
not reachable from other machines on the LAN, which for a development
cluster is rarely a loss.


Configuration
=============

Edit ``nixos/hosts/dev-local-microvm.nix``:

- Set ``network.address`` to an address inside your ``br0`` subnet
- Set ``network.gateway`` to the workstation's own address on ``br0``
- Set ``network.nameservers`` to a resolver the guest can reach
  through the NAT
- Add your SSH public key

Edit ``ansible/inventory-dev-local-microvm.yaml``:

- Set ``ansible_host`` to the guest address
- Set ``microvm_host`` to the workstation's address on ``br0``

``microvm_host`` is how ansible reaches the hypervisor, which here is
the workstation itself. Its ``br0`` address works for both, so the
deploy needs no special case for the local host.


Deployment
==========

Enter the ansible development shell:

.. code-block:: bash

   nix develop ./external/business-operations#ansible

Deploy the microVM and start it:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-dev-local-microvm.yaml \
     $BO_PLAYBOOKS/deploy-microvms.yaml

Verify SSH access:

.. code-block:: bash

   ssh root@<guest-ip> hostname

Bootstrap the Kubernetes cluster:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-dev-local-microvm.yaml \
     $BO_PLAYBOOKS/bootstrap-existing-machines.yaml


Result
======

A single-node Kubernetes cluster running on your workstation, with the
application layer left off --- the inventory sets ``skip_rook_ceph``
and declares no ``cluster_path``, so the bootstrap stops once Cilium
and OpenEBS are in and there is no Flux step to run.

The guest takes its closure from the workstation's own Nix store over
virtiofs, so a configuration change is built locally and is already
present in the guest. Rebuilding it fetches nothing.
