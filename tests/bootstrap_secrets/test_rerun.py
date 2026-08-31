from .helpers import decrypt_sops_file

GITEA_SECRET = "kubernetes/cluster-demo/bootstrap/gitea/secret-bootstrap.sops.yaml"


def test_keeps_an_existing_password(bootstrapped_repo, run_bootstrap):
    gitea_secret = bootstrapped_repo.path / GITEA_SECRET

    original = decrypt_sops_file(gitea_secret, bootstrapped_repo.user_key)
    original_password = original["stringData"]["password"]

    run_bootstrap()

    rerun = decrypt_sops_file(gitea_secret, bootstrapped_repo.user_key)
    assert rerun["stringData"]["password"] == original_password


def test_writes_a_secret_that_is_missing(bootstrapped_repo, run_bootstrap):
    gitea_secret = bootstrapped_repo.path / GITEA_SECRET
    gitea_secret.unlink()

    run_bootstrap()

    restored = decrypt_sops_file(gitea_secret, bootstrapped_repo.user_key)
    assert restored["stringData"]["password"]


def test_leaves_hand_edited_values_alone(bootstrapped_repo, run_bootstrap):
    settings = (
        bootstrapped_repo.path
        / "kubernetes/cluster-demo/flux/vars/secret-cluster-settings.sops.yaml"
    )
    original = settings.read_bytes()

    run_bootstrap()

    assert settings.read_bytes() == original
