import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "bootstrap-secrets.sh"

TEMPLATE_FILES = [
    "kubernetes/cluster-demo/bootstrap/age-key.template.yaml",
    "kubernetes/cluster-demo/bootstrap/gitea/secret-bootstrap.template.yaml",
    "kubernetes/cluster-demo/flux/vars/secret-cluster-settings.template.yaml",
]


@pytest.fixture()
def repo_dir(tmp_path):
    """Create a minimal repo structure with template files in a temp directory."""
    for template_file in TEMPLATE_FILES:
        source = REPO_ROOT / template_file
        destination = tmp_path / template_file
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)

    (tmp_path / ".secrets").mkdir(exist_ok=True)
    (tmp_path / ".gitignore").write_text(".secrets/\n")

    script_destination = tmp_path / "scripts" / "bootstrap-secrets.sh"
    script_destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SCRIPT, script_destination)

    return tmp_path


@pytest.fixture()
def run_bootstrap(repo_dir):
    """Return a callable that runs the bootstrap script in the repo dir."""

    def _run(*, env=None):
        return subprocess.run(
            [str(repo_dir / "scripts" / "bootstrap-secrets.sh")],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            env=env,
        )

    return _run


@pytest.fixture()
def bootstrapped_repo(repo_dir, run_bootstrap):
    """Run the bootstrap script and return the repo dir."""
    run_bootstrap()
    return repo_dir
