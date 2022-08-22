#!/usr/bin/env bash
#
# Our little test runner.

set -euo pipefail

cd "$(dirname "$0")"

extra_flags=""

if [[ "$#" -eq 1 ]]; then
    extra_flags="-A $1"
fi

# Need to build first or the store paths don't exist
# for default.nix to traverse
nix-build >/dev/null
echo "---------------------------------------------------------------------"
results="$(nix-instantiate --eval --strict --json $extra_flags 2>/dev/null)"

# Normalize input before handing it over to jq
if [[ -n "$extra_flags" ]] && [[ "${1::1}" != "@" ]]; then
    results="{ \"$1\": $results }"
fi

# Parse and format the results with jq
#
# This expects the JSON format to look like:
#     { "test-case-name": [ { "path": "./path/to/file", "status": "missing" } ] }
#
# There is a special case ("@onlyFailures") which is a key with
# the expected format nested inside of it. In order to not choke
# on this "report" style of key, we filter out keys starting with
# "@".
result_string=$(
    echo "$results" |\
        jq -r '
            "\\e[0;91m" as $red |
            "\\e[0;92m" as $green |
            "\\e[0m" as $reset |
            to_entries |
            map(select(.key|startswith("@") == false)) |
                (
                    map(
                        (.value|length) as $errors |
                        "TEST: " + .key + " " +
                        (
                            if $errors > 0
                            then $red + "(" + ($errors|tostring) + " errors"
                            else $green + "(SUCCESS" end
                        ) +
                        ")" + $reset + "\n" +
                        ( .value |
                            map(
                                "  " +
                                (
                                    if .status == "missing"
                                    then "MISSING "
                                    else "EXTRA   " end
                                ) +
                                .path + "\n"
                            ) | add
                        )
                    )|.[]
                ),
                (
                    [ (map(select(.value|length > 0))|length)
                    , (map(select(.value|length == 0))|length)
                    ] |
                    "Tests completed. " +
                    (
                        if .[1] > 0
                        then $green + (.[1]|tostring) + " succeeded" + $reset + ". "
                        else "" end
                    ) +
                    (
                        if .[0] > 0
                        then $red + (.[0]|tostring) + " failed" + $reset + "."
                        else "" end
                    )
                )'
)

echo -e "$result_string"

# If there are errors in the output, return a non-zero exit code
if grep -Po "^TEST:.*?\(\d+ errors\)" <<< "$result_string" &>/dev/null; then
    exit 1
fi
