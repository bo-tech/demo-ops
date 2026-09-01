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
``cluster_domain`` from ``flux/vars/cluster-settings.yaml`` under the
cluster you deployed in ``kubernetes/``. The
cluster publishes no DNS, so the names have to resolve to
``cluster_ingress_ip`` from the workstation you browse from — through
entries in its ``/etc/hosts``, or records in whichever resolver it
uses:

.. code-block:: text

   192.0.2.4  lldap.business-operations.example
   192.0.2.4  auth.business-operations.example

Both names are needed. LLDAP is itself protected by Authelia, so
opening it redirects to ``https://auth.<cluster_domain>`` and the
redirect dead-ends if that name does not resolve.

The wildcard certificate comes from the cluster's own self-signed
issuer, so the browser warns on the first visit. Accept it, then log
in at Authelia with the `admin` credentials. Authelia authenticates
against LLDAP and returns you to it, where you can manage users and
groups.

The same credentials work for every other Authelia-protected service.
