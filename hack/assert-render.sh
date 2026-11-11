#!/usr/bin/env bash
#
# Checks rendered manifests against Chainsaw assertions, without a cluster.
#
#   hack/assert-render.sh <rendered.yml> <scenario-dir>
#
# - Each document in <scenario-dir>/assert.yaml must match at least one rendered resource.
# - No document in <scenario-dir>/errors.yaml may match any rendered resource.
#
# Documents use the Chainsaw assertion syntax (https://kyverno.github.io/chainsaw/latest/quick-start/assertion-trees/).
# They're compared with the rendered resources of the same apiVersion and kind,
# narrowed down by name and namespace when the document sets them.
#
# A failed `chainsaw assert` takes about a second, so the comparisons run in parallel.

set -euo pipefail

absolute() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }

rendered=$(absolute "$1")
scenario=$2

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Prints one "apiVersion|kind|name|namespace" line per document of the given file.
index() {
  yq -N '[.apiVersion // "", .kind // "", .metadata.name // "", .metadata.namespace // ""] | join("|")' "$1"
}

# Splits a multi-document file into one file per document (<dir>/0.yml, <dir>/1.yml, ...) and indexes them.
split() {
  mkdir -p "$2"
  (cd "$2" && yq -s '$index' "$1")
  index "$1" > "$2/index"
}

describe() {
  yq -N '[.kind, .metadata.namespace, .metadata.name] | map(select(. != null)) | join("/")' "$1"
}

split "$rendered" "$work/resources"

# Lists the comparisons to run, as "<expected document> <rendered resource>" lines.
for mode in assert errors; do
  [[ -f $scenario/$mode.yaml ]] || continue
  split "$(absolute "$scenario/$mode.yaml")" "$work/$mode"
  e=0
  while IFS='|' read -r apiversion kind name namespace; do
    r=0
    while IFS='|' read -r r_apiversion r_kind r_name r_namespace; do
      if [[ $r_apiversion == "$apiversion" && $r_kind == "$kind" ]] &&
         [[ -z $name || $r_name == "$name" ]] &&
         [[ -z $namespace || $r_namespace == "$namespace" ]]; then
        echo "$work/$mode/$e.yml $work/resources/$r.yml"
      fi
      r=$((r + 1))
    done < "$work/resources/index"
    e=$((e + 1))
  done < "$work/$mode/index"
done > "$work/comparisons"

# Runs the comparisons. The result of each one is stored next to the expected document:
# <expected>.<resource>.pass when it matches, <expected>.<resource>.fail with the Chainsaw output otherwise.
# shellcheck disable=SC2016
[[ -s $work/comparisons ]] && xargs -P 8 -L 1 bash -c '
  result="$0.$(basename "$1" .yml)"
  if chainsaw assert --no-color -r "$1" -f "$0" > "$result.out" 2>&1; then
    mv "$result.out" "$result.pass"
  else
    mv "$result.out" "$result.fail"
  fi
' < "$work/comparisons"

failures=0

for mode in assert errors; do
  [[ -f $work/$mode/index ]] || continue
  for expected in "$work/$mode"/[0-9]*.yml; do
    matches=$(find "$work/$mode" -name "$(basename "$expected").*.pass" | wc -l | tr -d ' ')
    if [[ $mode == assert && $matches -eq 0 ]]; then
      echo "❌ No rendered resource matches the assertion for $(describe "$expected")"
      failure=$(find "$work/$mode" -name "$(basename "$expected").*.fail" | head -1)
      if [[ -n $failure ]]; then
        sed 's/^/   /' "$failure"
      else
        echo "   No $(describe "$expected") was rendered."
      fi
      failures=$((failures + 1))
    elif [[ $mode == errors && $matches -gt 0 ]]; then
      echo "❌ $matches rendered resource(s) match the error assertion for $(describe "$expected"), expected none"
      failures=$((failures + 1))
    fi
  done
done

if [[ $failures -gt 0 ]]; then
  exit 1
fi
