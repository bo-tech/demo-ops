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


def test_lldap_password_stays_the_same_on_both_sides(bootstrapped_repo, run_bootstrap):
    lldap = bootstrapped_repo.path / (
        "kubernetes/cluster-demo/apps/security/lldap/app/lldap-secret.sops.yaml"
    )
    authelia = bootstrapped_repo.path / (
        "kubernetes/cluster-demo/apps/security/authelia/app/authelia-secret.sops.yaml"
    )
    authelia.unlink()

    run_bootstrap()

    stored = decrypt_sops_file(lldap, bootstrapped_repo.user_key)
    binding = decrypt_sops_file(authelia, bootstrapped_repo.user_key)
    assert (
        binding["stringData"]["AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD"]
        == stored["stringData"]["LLDAP_LDAP_USER_PASS"]
    )


def test_leaves_hand_edited_values_alone(bootstrapped_repo, run_bootstrap):
    settings = (
        bootstrapped_repo.path
        / "kubernetes/cluster-demo/flux/vars/secret-cluster-settings.sops.yaml"
    )
    original = settings.read_bytes()

    run_bootstrap()

    assert settings.read_bytes() == original
