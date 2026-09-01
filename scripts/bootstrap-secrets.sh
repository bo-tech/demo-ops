#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_DIR="$REPO_ROOT/.secrets"
CLUSTER_KEY="$SECRETS_DIR/age-cluster.key"
USER_KEY="$SECRETS_DIR/age-user.key"
SOPS_CONFIG="$REPO_ROOT/.sops.yaml"

CLUSTER_DIRS=(
    kubernetes/cluster-demo
    kubernetes/cluster-demo-multi-node
)

SECRET_NAMES=(
    bootstrap/age-key
    bootstrap/gitea/secret-bootstrap
    flux/vars/secret-cluster-settings
    secrets/webhook-token
    apps/security/authelia/app/authelia-secret
    apps/security/lldap/app/lldap-secret
)

main() {
    case "${1:-}" in
        --regenerate-secrets) regenerate ;;
        "") bootstrap ;;
        *) echo "Usage: $0 [--regenerate-secrets]" >&2; exit 1 ;;
    esac
}

bootstrap() {
    check_prerequisites
    if keys_exist; then
        read_existing_keys
        write_sops_config
        write_secrets missing
        echo "Reused existing keys, wrote the secrets that were missing"
    else
        check_not_bootstrapped
        generate_age_keys
        write_sops_config
        write_secrets missing
        print_summary
    fi
}

keys_exist() {
    [[ -f "$CLUSTER_KEY" && -f "$USER_KEY" ]]
}

regenerate() {
    check_prerequisites
    check_bootstrapped
    read_existing_keys
    write_secrets all
    echo "Secrets regenerated and encrypted"
}

check_bootstrapped() {
    local missing=()
    [[ -f "$CLUSTER_KEY" ]] || missing+=("$CLUSTER_KEY")
    [[ -f "$USER_KEY" ]] || missing+=("$USER_KEY")
    [[ -f "$SOPS_CONFIG" ]] || missing+=("$SOPS_CONFIG")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Not yet bootstrapped. Missing:" >&2
        printf '  %s\n' "${missing[@]}" >&2
        echo "Run $0 first (without flags) to bootstrap." >&2
        exit 1
    fi
}

read_existing_keys() {
    CLUSTER_PUB=$(grep -o 'age1.*' "$CLUSTER_KEY" | head -1)
    USER_PUB=$(grep -o 'age1.*' "$USER_KEY" | head -1)
}

check_prerequisites() {
    local missing=()
    command -v age-keygen >/dev/null 2>&1 || missing+=(age-keygen)
    command -v sops >/dev/null 2>&1 || missing+=(sops)
    command -v envsubst >/dev/null 2>&1 || missing+=(envsubst)

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required tools: ${missing[*]}" >&2
        echo "The dev shell carries them: nix develop" >&2
        exit 1
    fi
}

check_not_bootstrapped() {
    local existing=()
    [[ -f "$CLUSTER_KEY" ]] && existing+=("$CLUSTER_KEY")
    [[ -f "$USER_KEY" ]] && existing+=("$USER_KEY")
    [[ -f "$SOPS_CONFIG" ]] && existing+=("$SOPS_CONFIG")

    if [[ ${#existing[@]} -gt 0 ]]; then
        echo "ERROR: Already bootstrapped. Found:" >&2
        printf '  %s\n' "${existing[@]}" >&2
        exit 1
    fi
}

generate_age_keys() {
    mkdir -p "$SECRETS_DIR"

    age-keygen -o "$CLUSTER_KEY"
    CLUSTER_PUB=$(grep -o 'age1.*' "$CLUSTER_KEY" | head -1)
    echo "Generated cluster key: $CLUSTER_PUB"

    age-keygen -o "$USER_KEY"
    USER_PUB=$(grep -o 'age1.*' "$USER_KEY" | head -1)
    echo "Generated user key: $USER_PUB"
}

write_sops_config() {
    cat > "$SOPS_CONFIG" <<YAML
creation_rules:
  - path_regex: kubernetes/cluster-.*/.*\\.sops\\.ya?ml
    encrypted_regex: "^(data|stringData)$"
    # Cluster key, User key
    age: >-
      ${CLUSTER_PUB},
      ${USER_PUB}
YAML
    echo "Wrote $SOPS_CONFIG"
}

# Skipping a cluster that already has its secrets is what stops one
# cluster's bootstrap from handing another, already deployed,
# credentials it does not know.
write_secrets() {
    local mode="$1"
    local cluster_dir

    export SOPS_AGE_KEY_FILE="$USER_KEY"

    for cluster_dir in "${CLUSTER_DIRS[@]}"; do
        if [[ "$mode" == missing ]] && cluster_has_all_secrets "$cluster_dir"; then
            echo "Kept the secrets of $cluster_dir"
            continue
        fi

        generate_cluster_values
        write_cluster_secrets "$cluster_dir"
    done
}

cluster_has_all_secrets() {
    local cluster_dir="$1"
    local name

    for name in "${SECRET_NAMES[@]}"; do
        [[ -f "$REPO_ROOT/$cluster_dir/$name.sops.yaml" ]] || return 1
    done
}

# A cluster's secrets are written as one set: LLDAP_PASSWORD reaches
# both lldap-secret and authelia-secret, which Authelia binds with, so
# renewing one file alone would leave the two disagreeing.
write_cluster_secrets() {
    local cluster_dir="$1"
    local name secret

    for name in "${SECRET_NAMES[@]}"; do
        secret="$REPO_ROOT/$cluster_dir/$name.sops.yaml"
        envsubst < "$REPO_ROOT/$cluster_dir/$name.template.yaml" > "$secret"
        sops -e -i "$secret"
        echo "Wrote $cluster_dir/$name.sops.yaml"
    done
}

# Called once per cluster, so that two clusters never share a password.
generate_cluster_values() {
    export CLUSTER_AGE_KEY
    CLUSTER_AGE_KEY=$(grep -v '^#' "$CLUSTER_KEY" | tr -d '\n')

    export GITEA_PASSWORD
    GITEA_PASSWORD=$(openssl rand -hex 32)

    export CERT_MANAGER_AWS_ACCESS_KEY_ID="CHANGE-ME"
    export CERT_MANAGER_AWS_HOSTED_ZONE_ID="CHANGE-ME"
    export CNPG_BACKUP_ENDPOINT="CHANGE-ME"
    export CNPG_RESTORE_ENDPOINT="CHANGE-ME"

    export WEBHOOK_TOKEN
    WEBHOOK_TOKEN=$(openssl rand -hex 32)
    export WEBHOOK_TOKEN_PATH
    WEBHOOK_TOKEN_PATH=$(echo -n "${WEBHOOK_TOKEN}gitea-receiverflux-bootstrap" \
        | shasum -a 256 | awk '{print $1}')

    export LLDAP_USER_DN="uid=admin,ou=people,dc=lab,dc=bo-tech,dc=de"
    export LLDAP_PASSWORD
    LLDAP_PASSWORD=$(openssl rand -hex 32)
    export LLDAP_JWT_SECRET
    LLDAP_JWT_SECRET=$(openssl rand -hex 32)
    export LLDAP_SERVER_KEY_SEED
    LLDAP_SERVER_KEY_SEED=$(openssl rand -hex 32)
    export AUTHELIA_JWT_SECRET
    AUTHELIA_JWT_SECRET=$(openssl rand -hex 32)
    export AUTHELIA_SESSION_SECRET
    AUTHELIA_SESSION_SECRET=$(openssl rand -hex 32)
    export AUTHELIA_STORAGE_ENCRYPTION_KEY
    AUTHELIA_STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 32)
}

print_summary() {
    cat <<SUMMARY

=== Bootstrap complete ===

Keys:
  Cluster key: $CLUSTER_KEY
  User key:    $USER_KEY

SOPS config: $SOPS_CONFIG

Encrypted secrets:
$(list_secrets)

Next steps:
  1. Keep .secrets/ safe — it is gitignored but not backed up
  2. Update the CHANGE-ME values in each cluster's
     flux/vars/secret-cluster-settings.sops.yaml:
     SOPS_AGE_KEY_FILE=$USER_KEY sops <file>
  3. Commit .sops.yaml and the encrypted secret files to git
SUMMARY
}

list_secrets() {
    local cluster_dir name

    for cluster_dir in "${CLUSTER_DIRS[@]}"; do
        for name in "${SECRET_NAMES[@]}"; do
            echo "  $cluster_dir/$name.sops.yaml"
        done
    done
}

main "$@"
