#!/usr/bin/env bash
#
# Prints the given Markdown file with the table of configurable values regenerated
# from the values schema, between the `values-table:start` and `values-table:end` markers.
#
#   hack/values-table.sh README.md

set -eo pipefail

table=$(mktemp)
trap 'rm -f "$table"' EXIT

ytt -f package/config --data-values-schema-inspect -o openapi-v3 | yq -o json | jq -r -f hack/values-table.jq > "$table"

awk -v table="$table" '
  /<!-- values-table:start -->/ {
    print; print ""
    while ((getline line < table) > 0) print line
    print ""; skip = 1; next
  }
  /<!-- values-table:end -->/ { skip = 0 }
  !skip { print }
' "$1"
