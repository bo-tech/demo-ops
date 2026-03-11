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
