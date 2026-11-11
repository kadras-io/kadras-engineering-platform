# Renders the package values schema (OpenAPI v3) as a Markdown table, one row per leaf property.
def rows(prefix):
  .properties // {} | to_entries[] |
  (prefix + .key) as $path |
  if .value.type == "object" and (.value.properties // {} | length) > 0 then
    .value | rows($path + ".")
  else
    "| `\($path)` | `\(.value.default | if type == "string" then "\"" + . + "\"" else tojson end)` | \(.value.description // "" | gsub("\n"; " ")) |"
  end;

"| Config | Default | Description |",
"|--------|---------|-------------|",
(.components.schemas.dataValues | rows(""))
