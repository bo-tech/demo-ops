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

A deploy over an existing guest is a switch
===========================================

``deploy-microvms.yaml`` installs the new closure on the hypervisor and
then activates it. On a hypervisor that already carries the guest it
therefore updates the machine rather than creating one — the microvm.nix
equivalent of ``nixos-rebuild switch``. ``/var/lib/microvms/<guest>``
stays, and with it ``var.img`` and ``ceph.img``, so the machine comes
back carrying the etcd and the Flux installation it had before. That is
what a deploy means here rather than a fault in it.

The guides assume a hypervisor with no guest on it, so following one a
second time does not produce what it describes. The cluster that comes
back is the previous one, and the bootstrap then runs against a Flux
that is already reconciling. Whatever it reports, the state is the old
guest's rather than a fresh cluster's.

Destroy the guests first to deploy a machine from scratch. The playbook
stops each ``microvm@`` unit and removes the directory above:

.. code-block:: bash

   ansible-playbook -i ./ansible/inventory-microvm.yaml \
     $BO_PLAYBOOKS/destroy-microvms.yaml

Pass whichever inventory the deploy used —
``inventory-three-node-microvm.yaml`` destroys all three guests. This
discards the cluster along with its data.
