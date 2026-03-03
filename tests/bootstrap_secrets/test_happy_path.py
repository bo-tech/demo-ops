import pytest

from ruamel.yaml import YAML

from .helpers import decrypt_sops_file

ENCRYPTED_SECRET_FILES = [
    "kubernetes/cluster-demo/bootstrap/age-key.sops.yaml",
    "kubernetes/cluster-demo/bootstrap/gitea/secret-bootstrap.sops.yaml",
    "kubernetes/cluster-demo/flux/vars/secret-cluster-settings.sops.yaml",
]


def test_generates_age_keys(bootstrapped_repo):
    cluster_key = bootstrapped_repo / ".secrets" / "age-cluster.key"
    user_key = bootstrapped_repo / ".secrets" / "age-user.key"

    assert cluster_key.exists()
    assert user_key.exists()
    assert "AGE-SECRET-KEY-" in cluster_key.read_text()
    assert "AGE-SECRET-KEY-" in user_key.read_text()


def test_creates_sops_config(bootstrapped_repo):
    sops_config = bootstrapped_repo / ".sops.yaml"
    assert sops_config.exists()

    content = YAML().load(sops_config.read_text())
    age_keys = content["creation_rules"][0]["age"]
    assert age_keys.count("age1") == 2


@pytest.mark.parametrize("secret_file", ENCRYPTED_SECRET_FILES)
def test_encrypts_secret_files(bootstrapped_repo, secret_file):
    path = bootstrapped_repo / secret_file
    assert path.exists()
    content = path.read_text()
    assert "sops:" in content
    assert "age:" in content


def test_age_key_secret_contains_cluster_key(bootstrapped_repo):
    user_key = bootstrapped_repo / ".secrets" / "age-user.key"
    decrypted = decrypt_sops_file(
        bootstrapped_repo / "kubernetes/cluster-demo/bootstrap/age-key.sops.yaml",
        user_key,
    )

    cluster_key_content = (bootstrapped_repo / ".secrets" / "age-cluster.key").read_text()
    private_key = [
        line for line in cluster_key_content.splitlines() if not line.startswith("#")
    ][0]
    assert private_key in decrypted["stringData"]["age.agekey"]


def test_gitea_secret_has_random_password(bootstrapped_repo):
    user_key = bootstrapped_repo / ".secrets" / "age-user.key"
    decrypted = decrypt_sops_file(
        bootstrapped_repo / "kubernetes/cluster-demo/bootstrap/gitea/secret-bootstrap.sops.yaml",
        user_key,
    )

    password = decrypted["stringData"]["password"]
    assert password not in ("stub-value", "__GITEA_PASSWORD__")
    assert len(password) > 20


def test_reuses_existing_keys_when_secrets_missing(bootstrapped_repo, run_bootstrap):
    cluster_key = bootstrapped_repo / ".secrets" / "age-cluster.key"
    user_key = bootstrapped_repo / ".secrets" / "age-user.key"
    original_cluster = cluster_key.read_text()
    original_user = user_key.read_text()

    for secret_file in ENCRYPTED_SECRET_FILES:
        (bootstrapped_repo / secret_file).unlink()

    result = run_bootstrap()

    assert result.returncode == 0
    assert cluster_key.read_text() == original_cluster
    assert user_key.read_text() == original_user
    for secret_file in ENCRYPTED_SECRET_FILES:
        assert (bootstrapped_repo / secret_file).exists()


def test_prints_summary(repo_dir, run_bootstrap):
    result = run_bootstrap()

    assert result.returncode == 0
    assert "Bootstrap complete" in result.stdout
    assert ".secrets/age-cluster.key" in result.stdout
    assert ".secrets/age-user.key" in result.stdout
