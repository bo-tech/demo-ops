import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
SINGLE_NODE = REPO_ROOT / "kubernetes/cluster-demo"
MULTI_NODE = REPO_ROOT / "kubernetes/cluster-demo-multi-node"

INTENDED_DIFFERENCES = {
    "flux/vars/cluster-settings.yaml",
    "base-apps/rook-ceph/kustomization.yaml",
    "flux/config/kustomization.yaml",
}


def non_secret_files(cluster_dir):
    listing = subprocess.run(
        ["git", "ls-files", "-z", "--", str(cluster_dir)],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return {
        str(Path(name).relative_to(cluster_dir.relative_to(REPO_ROOT)))
        for name in listing.stdout.split("\0")
        if name and not name.endswith(".sops.yaml")
    }


def shared_files():
    return sorted(non_secret_files(SINGLE_NODE) - INTENDED_DIFFERENCES)


def test_both_clusters_hold_the_same_files():
    assert non_secret_files(SINGLE_NODE) == non_secret_files(MULTI_NODE)


def normalized(cluster_dir, name):
    return (cluster_dir / name).read_text().replace(
        f"./kubernetes/{cluster_dir.name}/", "./kubernetes/<cluster>/"
    )


@pytest.mark.parametrize("name", shared_files())
def test_shared_file_has_not_drifted(name):
    assert normalized(SINGLE_NODE, name) == normalized(MULTI_NODE, name)


@pytest.mark.parametrize("name", sorted(INTENDED_DIFFERENCES))
def test_intended_difference_actually_differs(name):
    assert (SINGLE_NODE / name).read_text() != (MULTI_NODE / name).read_text()
