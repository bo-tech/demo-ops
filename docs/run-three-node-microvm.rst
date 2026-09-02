=============================
 Running three MicroVM nodes
=============================

This guide deploys demo-ops as three microVM nodes, one per hypervisor,
giving a cluster that keeps running when a node goes away. It is the
multi-node counterpart of :doc:`run-microvm`, and it builds the
``cluster-demo-multi-node`` cluster rather than ``cluster-demo``.

Every node is a controller as well as a worker. What the platform needs
for that is covered in :ref:`bo:sec-multiple-controllers`.


Prerequisites
=============

- Nix installed on your workstation
- Three NixOS hosts prepared for microVMs — see
  :doc:`bo:kubernetes/microvm` for the required modules and host setup
- All three on the same network segment

Each guest attaches to a bridge on its own hypervisor and lands on
whatever network that host's NIC is on, so hypervisors on different
segments produce guests that cannot reach each other.


Configuration
=============

The nodes
---------

``nixos/hosts/demo-nodes.nix`` holds the three nodes as data, and is
the only file to edit for them:

- Set ``network.gateway`` for your network
- Add your SSH public key to ``sshAuthorizedKeys``
- Set the three ``address`` values, and adjust the MAC addresses if
  needed

The addresses must be free, and outside whatever the network hands out
over DHCP.

The inventory
-------------

Edit ``ansible/inventory-three-node-microvm.yaml``:

- Set each ``ansible_host`` to the matching guest address
- Set each ``microvm_host`` to the hypervisor that guest runs on

``demo-node-01-microvm`` is the ``initial_controller``, and the cluster
settings below name its address.

The cluster
-----------

Set the load balancer addresses in
``kubernetes/cluster-demo-multi-node/flux/vars/cluster-settings.yaml``.
The Cilium pools and ``cluster_ingress_ip`` must lie inside the guests'
subnet; :doc:`getting-started` explains why.

Set ``cluster_service_host`` to the address of the first node. The
cluster has no single API address, so this names one controller rather
than the cluster.

.. note::

   ``cluster-demo`` and ``cluster-demo-multi-node`` ship the same
   placeholder addresses and the same ``cluster_domain``. To run both
   clusters at once, give this one addresses and a domain of its own.

Commit the changes before deploying — the flake only sees files that
are in git.


Deployment
==========

Enter the ansible development shell:

.. code-block:: bash

   nix develop ./external/business-operations#ansible

Export the path to the age key. ``bootstrap-cluster.yaml`` decrypts a
SOPS file, and fails at that step without it:

.. code-block:: bash

   export SOPS_AGE_KEY_FILE="${PWD}/.secrets/age-user.key"

Deploy the three guests to their hypervisors:

.. note::

   This assumes no hypervisor carries its guest yet. Deploying over one
   keeps its volumes, and the failure surfaces two steps later — see
   :ref:`sec-redeploy-over-existing-guest`.

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-three-node-microvm.yaml \
     $BO_PLAYBOOKS/deploy-microvms.yaml

Bootstrap the Kubernetes cluster:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-three-node-microvm.yaml \
     $BO_PLAYBOOKS/bootstrap-existing-machines.yaml

The first node generates the join tokens and the other two join with
them. They sit idle until their token arrives, which is expected rather
than a hang.

Kick off FluxCD:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-three-node-microvm.yaml \
     $BO_PLAYBOOKS/bootstrap-cluster.yaml


Result
======

Three nodes, each a controller and a worker, with etcd surviving the
loss of one of them, and Ceph replicating across the three.

See :doc:`first-login` for accessing the deployed applications.
