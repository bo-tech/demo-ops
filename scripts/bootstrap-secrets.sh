#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_DIR="$REPO_ROOT/.secrets"
CLUSTER_KEY="$SECRETS_DIR/age-cluster.key"
USER_KEY="$SECRETS_DIR/age-user.key"
SOPS_CONFIG="$REPO_ROOT/.sops.yaml"

CLUSTER_DIR="$REPO_ROOT/kubernetes/cluster-demo"
AGE_KEY_SECRET="$CLUSTER_DIR/bootstrap/age-key.sops.yaml"
GITEA_SECRET="$CLUSTER_DIR/bootstrap/gitea/secret-bootstrap.sops.yaml"
CLUSTER_SETTINGS_SECRET="$CLUSTER_DIR/flux/vars/secret-cluster-settings.sops.yaml"

AGE_KEY_TEMPLATE="$CLUSTER_DIR/bootstrap/age-key.template.yaml"
GITEA_TEMPLATE="$CLUSTER_DIR/bootstrap/gitea/secret-bootstrap.template.yaml"
CLUSTER_SETTINGS_TEMPLATE="$CLUSTER_DIR/flux/vars/secret-cluster-settings.template.yaml"

main() {
    check_prerequisites
    check_not_bootstrapped
    generate_age_keys
    write_sops_config
    generate_secrets
    encrypt_secrets
    print_summary
}

check_prerequisites() {
    local missing=()
    command -v age-keygen >/dev/null 2>&1 || missing+=(age-keygen)
    command -v sops >/dev/null 2>&1 || missing+=(sops)

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing required tools: ${missing[*]}" >&2
        echo "Install with: nix shell nixpkgs#age nixpkgs#sops" >&2
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
  - path_regex: kubernetes/cluster-demo/.*\\.sops\\.ya?ml
    encrypted_regex: "^(data|stringData)$"
    # Cluster key, User key
    age: >-
      ${CLUSTER_PUB},
      ${USER_PUB}
YAML
    echo "Wrote $SOPS_CONFIG"
}

generate_secrets() {
    export CLUSTER_AGE_KEY
    CLUSTER_AGE_KEY=$(grep -v '^#' "$CLUSTER_KEY" | tr -d '\n')

    export GITEA_PASSWORD
    GITEA_PASSWORD=$(openssl rand -hex 32)

    export CERT_MANAGER_AWS_ACCESS_KEY_ID="CHANGE-ME"
    export CERT_MANAGER_AWS_HOSTED_ZONE_ID="CHANGE-ME"
    export CNPG_BACKUP_ENDPOINT="CHANGE-ME"
    export CNPG_RESTORE_ENDPOINT="CHANGE-ME"

    envsubst < "$AGE_KEY_TEMPLATE" > "$AGE_KEY_SECRET"
    envsubst < "$GITEA_TEMPLATE" > "$GITEA_SECRET"
    envsubst < "$CLUSTER_SETTINGS_TEMPLATE" > "$CLUSTER_SETTINGS_SECRET"

    echo "Generated secret files from templates"
}

encrypt_secrets() {
    export SOPS_AGE_KEY_FILE="$USER_KEY"
    sops -e -i "$AGE_KEY_SECRET"
    sops -e -i "$GITEA_SECRET"
    sops -e -i "$CLUSTER_SETTINGS_SECRET"
    echo "Encrypted all secret files"
}

print_summary() {
    cat <<SUMMARY

=== Bootstrap complete ===

Keys:
  Cluster key: $CLUSTER_KEY
  User key:    $USER_KEY

SOPS config: $SOPS_CONFIG

Encrypted secrets:
  $AGE_KEY_SECRET
  $GITEA_SECRET
  $CLUSTER_SETTINGS_SECRET

Next steps:
  1. Keep .secrets/ safe — it is gitignored but not backed up
  2. Update placeholder values in secret-cluster-settings.sops.yaml:
     SOPS_AGE_KEY_FILE=$USER_KEY sops $CLUSTER_SETTINGS_SECRET
  3. Commit .sops.yaml and the encrypted secret files to git
SUMMARY
}

main
