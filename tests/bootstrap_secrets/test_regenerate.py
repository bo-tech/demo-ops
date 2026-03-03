from .helpers import decrypt_sops_file


def test_regenerates_with_new_password(bootstrapped_repo, run_bootstrap):
    gitea_secret = (
        bootstrapped_repo.path / "kubernetes/cluster-demo/bootstrap/gitea/secret-bootstrap.sops.yaml"
    )

    original = decrypt_sops_file(gitea_secret, bootstrapped_repo.user_key)
    original_password = original["stringData"]["password"]

    run_bootstrap("--regenerate-secrets")

    regenerated = decrypt_sops_file(gitea_secret, bootstrapped_repo.user_key)
    assert regenerated["stringData"]["password"] != original_password


def test_preserves_age_keys(bootstrapped_repo, run_bootstrap):
    original_cluster = bootstrapped_repo.cluster_key.read_text()
    original_user = bootstrapped_repo.user_key.read_text()

    run_bootstrap("--regenerate-secrets")

    assert bootstrapped_repo.cluster_key.read_text() == original_cluster
    assert bootstrapped_repo.user_key.read_text() == original_user


def test_fails_if_not_bootstrapped(repo_dir, run_bootstrap):
    result = run_bootstrap("--regenerate-secrets")

    assert result.returncode != 0
    assert "Not yet bootstrapped" in result.stderr
