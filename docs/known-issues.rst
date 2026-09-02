============
Known Issues
============


kexec hangs on aarch64 VMs (UTM/QEMU on Apple Silicon)
=======================================================

When re-deploying an already installed machine, nixos-anywhere uses kexec
to boot into the NixOS installer. On aarch64 VMs under UTM/QEMU with
Apple Hypervisor.framework, kexec may cause the VM to hang. Possible
causes include missing kernel config, PSCI/CPU enable method mismatches,
or HVF not properly handing off hypervisor state during kexec.

**Workaround:** Boot the VM from the NixOS installer ISO before
re-deploying and skip the kexec phase:

.. code-block:: bash

   nix run github:nix-community/nixos-anywhere -- \
     --flake '.#demo-single-node' \
     --phases disko,install,reboot \
     --target-host root@192.0.2.10

When using ansible, set ``nixos_anywhere_extra_flags`` in your inventory
accordingly.


.. _sec-redeploy-over-existing-guest:

A re-deploy keeps the guest's volumes
=====================================

``deploy-microvms.yaml`` installs the new closure on the hypervisor and
restarts the VM, but leaves ``/var/lib/microvms/<guest>`` in place. That
directory holds ``var.img`` and ``ceph.img``, so the machine comes back
carrying the etcd and the Flux installation it had before.

``bootstrap-cluster.yaml`` then fails at ``kubectl apply
--server-side``, reporting a field manager conflict against
``kustomize-controller``. The message names neither the guest nor the
state it collided with, so the cause is not apparent from it.

**Workaround:** destroy the guests before deploying. The playbook stops
each ``microvm@`` unit and removes the directory above:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-microvm.yaml \
     $BO_PLAYBOOKS/destroy-microvms.yaml

Pass whichever inventory the deploy used —
``inventory-three-node-microvm.yaml`` destroys all three guests.

This discards the cluster along with its data, which is what the deploy
guides assume — they walk a hypervisor that carries no guest yet.
