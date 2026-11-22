#!/usr/bin/env bash
# Validate release metadata and report device verification gaps before tagging.
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

version=${1:-}
if [[ $# != 1 || ! $version =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    fail "Usage: ./Scripts/check-release.sh MAJOR.MINOR.PATCH"
fi

heading=$(awk '/^## \[[0-9]/ { print; exit }' CHANGELOG.md)
if [[ $heading != "## [$version] - "* ]]; then
    fail "Latest changelog release must be $version."
fi
release_date=${heading#"## [$version] - "}
if ! [[ $release_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
    ! awk -v date="$release_date" 'BEGIN {
        split(date, parts, "-")
        year = parts[1] + 0
        month = parts[2] + 0
        day = parts[3] + 0
        split("31 28 31 30 31 30 31 31 30 31 30 31", days, " ")
        if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) days[2] = 29
        exit !(year > 0 && month >= 1 && month <= 12 && day >= 1 && day <= days[month])
    }'; then
    fail "Invalid release date in CHANGELOG.md: $release_date"
fi

awk -v heading="$heading" '
    $0 == heading { in_release = 1; next }
    in_release && /^## / { exit }
    in_release && /^### (Known limits|Verification limits)$/ { found = 1; exit }
    END { exit !found }
' CHANGELOG.md || fail "Missing release limits heading in the $version changelog entry."

grep -Fqx "Current: \`${version%.*}.x\`." SECURITY.md ||
    fail "SECURITY.md must list ${version%.*}.x as current."
grep -F '.package(url: "' README.md | grep -F "from: \"$version\")" >/dev/null ||
    fail "README.md install example must use $version."

if grep -rFn '<owner>' README.md CHANGELOG.md SECURITY.md Docs Sources; then
    fail "Release owner placeholder found."
elif [[ $? != 1 ]]; then
    fail "Could not scan release files for owner placeholders."
fi

awk -F '|' '
    /^\|/ {
        for (column = 3; column <= 4; column++) {
            if ($column ~ /^[[:space:]]*UNKNOWN[[:space:]]*$/) count++
        }
    }
    END { printf "UNKNOWN matrix cells: %d\n", count }
' Docs/SimulatorVsDevice.md
printf 'Release metadata checked for %s (%s).\n' "$version" "$release_date"
