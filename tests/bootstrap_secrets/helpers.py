import os
import subprocess

from ruamel.yaml import YAML


def decrypt_sops_file(path, key_file):
    result = subprocess.run(
        ["sops", "-d", str(path)],
        capture_output=True,
        text=True,
        check=True,
        env={**os.environ, "SOPS_AGE_KEY_FILE": str(key_file)},
    )
    return YAML().load(result.stdout)
