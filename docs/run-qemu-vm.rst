===================
 Running a QEMU VM
===================

This guide walks through running a local QEMU/KVM virtual machine on a
Linux host and deploying demo-ops into it. This is the simplest way to
try out the platform locally.


Prerequisites
=============

- A Linux host with KVM support (``/dev/kvm`` must exist)
- QEMU installed (``qemu-system-x86_64``)
- Bridge networking (``br0``) configured on the host — VMs appear on
  the LAN and can receive DHCP addresses
- Nix installed on the workstation
- NixOS installer image available
- Bios firmware for UEFI boot


Prepare UEFI firmware
---------------------

.. code-block:: bash

  nix build nixpkgs#OVMF.fd -o ~/w/ovmf


Prepare NixOS installer
-----------------------

Make sure to have an installer ISO ready to boot the machine from.

For repeated tests, it may be convenient to build an installer which has your
public ssh key already baked in:

See: https://nixos.org/manual/nixos/stable/#sec-building-image


Creating and booting the VM
===========================

1. Create a virtual disk
------------------------

.. code-block:: bash

  qemu-img create -f qcow2 ~/w/disks/demo-dev.qcow2 50G

2. Boot the VM on the bridge
----------------------------

.. code-block:: bash

  qemu-system-x86_64 \
    -enable-kvm -m 16G -smp 2 \
    -bios ~/w/ovmf/FV/OVMF.fd \
    -drive file=~/w/demo-dev.qcow2,format=qcow2,if=virtio \
    -cdrom ~/w/nixos-installer/iso/nixos-installer-x86_64-linux.iso \
    -boot d \
    -netdev bridge,id=net0,br=br0 \
    -device virtio-net-pci,netdev=net0 \
    -nographic

The ``-nographic`` flag runs the VM headless — the serial console
appears in your terminal.

Adjust ``-m`` and ``-smp`` depending on your needs.


3. Wait until installer boots
-----------------------------

Wait for the installer to boot. Note the DHCP IP address from the
console output (or check your router's lease table).

.. note::

   You may have to select items from the boot menu in case you did already
   install previously into the machine.

   You can tweak things with the ``-boot`` option.


4. Verify SSH access
--------------------

Verify SSH access from the workstation:

.. code-block:: bash

  ssh root@<vm-ip> hostname


Deploying demo-ops
==================


Adjust host configuration
-------------------------

Adjust the host configuration, e.g. configure IP addresses and put a public SSH
key in.


Deploy the machine
------------------

With SSH access confirmed, deploy the demo-ops configuration into
the VM:

.. code-block:: bash

   nix run github:nix-community/nixos-anywhere -- \
     --flake '.#dev' \
     --target-host root@<vm-ip>

After reboot, verify that SSH still works against the deployed system.

.. note::

   If you started with the installer and then deployed a machine into it, the ip
   address likely has changed to the configured static ip.


QEMU console control
====================

With ``-nographic``, the VM console is your terminal. Useful
shortcuts:

``Ctrl-a x``
   Kill QEMU immediately.

``Ctrl-a h``
   Show all QEMU monitor shortcuts.

``poweroff``
   Run inside the VM for a graceful shutdown.
