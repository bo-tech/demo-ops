=================
Useful Commands
=================

Build the system closure:

.. code-block:: bash

   nix build '.#nixosConfigurations.demo-single-node.config.system.build.toplevel'

Deploy to a running machine via ``nixos-rebuild``:

.. code-block:: bash

   nixos-rebuild switch --flake '.#demo-single-node' \
     --target-host root@192.0.2.10

Inspect configuration values:

.. code-block:: bash

   nix eval '.#nixosConfigurations.demo-single-node.config.networking.hostName'
