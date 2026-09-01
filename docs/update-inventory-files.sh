#!/usr/bin/env bash
# Refresh the vendored intersphinx inventories.
#
# Sphinx resolves a cross-project reference out of the target's
# objects.inv at build time. A nix build has no network, so the file is
# committed rather than fetched. Nothing schedules this: run it when a
# referenced label has moved.
set -euo pipefail

cd "$(dirname "$0")"

curl -fsS -o _inventory/business-operations.inv \
  https://business-operations.codeberg.page/business-operations/objects.inv
