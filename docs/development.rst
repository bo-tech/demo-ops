===========
Development
===========

This page is for working on demo-ops itself. Deploying it is
:doc:`getting-started`.


The dev shell
=============

The repository ships a dev shell with the tools its scripts and tests
need:

.. code-block:: bash

   nix develop

It provides ``age-keygen`` and ``sops`` for the secrets, ``envsubst``
for filling the secret templates, ``openssl`` for the generated
credentials, and ``uv`` for the test suite.

The playbooks are a separate shell, provided by the platform:

.. code-block:: bash

   nix develop ./external/business-operations#ansible


Running the tests
=================

From the dev shell:

.. code-block:: bash

   uv run pytest
