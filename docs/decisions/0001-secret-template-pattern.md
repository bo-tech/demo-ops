---
date: 2026-03-03
---

(adr-0001)=
# ADR-0001 Secret Template Pattern

## Context and Problem Statement

Kubernetes clusters need secrets (age keys, Gitea credentials, webhook tokens,
etc.) that must be:

- Unique per cluster instance
- Encrypted at rest in the git repository (via SOPS)
- Reproducible from scratch during bootstrap

How should we manage the creation and encryption of these secrets?

## Considered Options

* Manual secret creation — write YAML by hand, encrypt with `sops -e -i`
* Sealed Secrets — encrypt against the cluster's public key
* Template-based generation — `.template.yaml` files with `envsubst`
  substitution, followed by SOPS encryption

## Decision Outcome

Chosen option: "Template-based generation" because:

- Templates live in version control and define the exact structure of each
  secret (name, namespace, keys) without containing sensitive values
- `envsubst` replaces placeholders (`${VAR}`) with generated or user-supplied
  values at bootstrap time
- SOPS encrypts the result in-place, producing `.sops.yaml` files that are
  safe to commit
- The bootstrap script (`scripts/bootstrap-secrets.sh`) orchestrates the full
  flow: key generation, template substitution, and encryption
- Adding a new secret is a three-step process: create a `.template.yaml`,
  register it in the bootstrap script, and add a test

### File layout

```
kubernetes/cluster-demo/
  bootstrap/
    age-key.template.yaml          -> age-key.sops.yaml
    gitea/
      secret-bootstrap.template.yaml -> secret-bootstrap.sops.yaml
  flux/vars/
    secret-cluster-settings.template.yaml -> secret-cluster-settings.sops.yaml
  secrets/
    webhook-token.template.yaml    -> webhook-token.sops.yaml
```

### Data flow

```
.template.yaml + environment variables
        |
    envsubst
        |
  plaintext .sops.yaml
        |
    sops -e -i
        |
  encrypted .sops.yaml (committed to git)
```
