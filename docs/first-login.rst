===========
First Login
===========

After deploying the cluster and Flux has reconciled all applications,
you can log into the system with the `admin` user.


Prerequisites
=============

- ``kubectl`` available on your workstation
- Kubeconfig pointing to the deployed cluster


Retrieve the `admin` password
=============================

The `admin` password is stored in the ``lldap-secret`` Kubernetes secret
in the ``security`` namespace. Extract it with:

.. code-block:: bash

   kubectl get secret lldap-secret -n security \
     -o jsonpath='{.data.LLDAP_LDAP_USER_PASS}' | base64 -d

The `admin` username is ``admin``.


Log into the web UI
===================

Open the LLDAP web interface in your browser and log in with the
`admin` credentials. From there you can manage users and groups.

All other applications are protected by Authelia, which authenticates
against LLDAP. The same `admin` credentials work for Authelia-protected
services.
