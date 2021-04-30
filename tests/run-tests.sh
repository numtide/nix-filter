#!/usr/bin/env bash
#
# Our little test runner.
#
set -euo pipefail

cd "$(dirname "$0")"

extra_flags=""

if [[ "$#" -eq 1 ]]; then
    extra_flags="-A $1"
fi


# Need to build first or the store paths don't exist
# for default.nix to traverse
nix-build &>/dev/null
nix-instantiate --eval --strict --json $extra_flags
