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

LLDAP is served at ``https://lldap.<cluster_domain>``, taking
``cluster_domain`` from
``kubernetes/cluster-demo/flux/vars/cluster-settings.yaml``. The
cluster publishes no DNS, so the name has to resolve to
``cluster_ingress_ip`` from the workstation you browse from — through
an entry in its ``/etc/hosts``, or a record in whichever resolver it
uses:

.. code-block:: text

   192.0.2.4  lldap.business-operations.example

The wildcard certificate comes from the cluster's own self-signed
issuer, so the browser warns on the first visit. Accept it, then log
in with the `admin` credentials. From there you can manage users and
groups.

All other applications are protected by Authelia, which authenticates
against LLDAP. The same `admin` credentials work for Authelia-protected
services.
