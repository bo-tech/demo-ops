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
    return {
        str(path.relative_to(cluster_dir))
        for path in cluster_dir.rglob("*")
        if path.is_file() and not path.name.endswith(".sops.yaml")
    }


def shared_files():
    return sorted(non_secret_files(SINGLE_NODE) - INTENDED_DIFFERENCES)


def test_both_clusters_hold_the_same_files():
    assert non_secret_files(SINGLE_NODE) == non_secret_files(MULTI_NODE)


@pytest.mark.parametrize("name", shared_files())
def test_shared_file_has_not_drifted(name):
    assert (SINGLE_NODE / name).read_text() == (MULTI_NODE / name).read_text()


@pytest.mark.parametrize("name", sorted(INTENDED_DIFFERENCES))
def test_intended_difference_actually_differs(name):
    assert (SINGLE_NODE / name).read_text() != (MULTI_NODE / name).read_text()
