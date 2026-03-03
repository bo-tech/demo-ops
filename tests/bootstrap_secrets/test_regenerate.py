from .helpers import decrypt_sops_file


def test_regenerates_with_new_password(bootstrapped_repo, run_bootstrap):
    user_key = bootstrapped_repo / ".secrets" / "age-user.key"
    gitea_secret = (
        bootstrapped_repo / "kubernetes/cluster-demo/bootstrap/gitea/secret-bootstrap.sops.yaml"
    )

    original = decrypt_sops_file(gitea_secret, user_key)
    original_password = original["stringData"]["password"]

    run_bootstrap("--regenerate-secrets")

    regenerated = decrypt_sops_file(gitea_secret, user_key)
    assert regenerated["stringData"]["password"] != original_password


def test_preserves_age_keys(bootstrapped_repo, run_bootstrap):
    cluster_key = bootstrapped_repo / ".secrets" / "age-cluster.key"
    user_key = bootstrapped_repo / ".secrets" / "age-user.key"

    original_cluster = cluster_key.read_text()
    original_user = user_key.read_text()

    run_bootstrap("--regenerate-secrets")

    assert cluster_key.read_text() == original_cluster
    assert user_key.read_text() == original_user


def test_fails_if_not_bootstrapped(repo_dir, run_bootstrap):
    result = run_bootstrap("--regenerate-secrets")

    assert result.returncode != 0
    assert "Not yet bootstrapped" in result.stderr
