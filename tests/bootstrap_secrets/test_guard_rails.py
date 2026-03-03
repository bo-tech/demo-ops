import os

import pytest


@pytest.mark.parametrize(
    "blocking_file",
    [
        ".secrets/age-cluster.key",
        ".secrets/age-user.key",
        ".sops.yaml",
    ],
    ids=["cluster_key", "user_key", "sops_config"],
)
def test_fails_if_already_bootstrapped(repo_dir, run_bootstrap, blocking_file):
    path = repo_dir / blocking_file
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("existing\n")

    result = run_bootstrap()

    assert result.returncode != 0
    assert "Already bootstrapped" in result.stderr


@pytest.mark.parametrize(
    "missing_tool",
    ["sops", "age-keygen"],
    ids=["sops", "age_keygen"],
)
def test_fails_if_tool_missing(repo_dir, run_bootstrap, missing_tool):
    path_without_tool = os.pathsep.join(
        d
        for d in os.environ["PATH"].split(os.pathsep)
        if not os.path.isfile(os.path.join(d, missing_tool))
    )

    env = {**os.environ, "PATH": path_without_tool}
    result = run_bootstrap(env=env)

    assert result.returncode != 0
    assert missing_tool in result.stderr
