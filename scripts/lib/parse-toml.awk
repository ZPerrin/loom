# parse-toml.awk — emit normalized "table.key=value" lines for loom's TOML subset.
# One line per scalar; one line per array element (repeated key). Exit 2 on any
# unsupported construct (array-of-tables, inline table, multiline, unparseable).
# Subset limits: single-line arrays only; array elements must not contain commas.
function strip(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function dequote(s) {
  s = strip(s)
  if (s ~ /^".*"$/) s = substr(s, 2, length(s) - 2)
  return s
}
/^[ \t]*#/   { next }   # full-line comment
/^[ \t]*$/   { next }   # blank
/^[ \t]*\[\[/ { print "parse-toml: unsupported array-of-tables: " $0 > "/dev/stderr"; exit 2 }
/^[ \t]*\[/  {          # [table]
  t = $0; sub(/^[ \t]*\[/, "", t); sub(/\][ \t]*$/, "", t); table = strip(t); next
}
index($0, "=") {
  eq  = index($0, "=")
  key = strip(substr($0, 1, eq - 1))
  val = strip(substr($0, eq + 1))
  if (val ~ /\{/) { print "parse-toml: unsupported inline table: " $0 > "/dev/stderr"; exit 2 }
  if (val ~ /^\[/) {
    if (val !~ /\]$/) { print "parse-toml: unsupported multiline array: " $0 > "/dev/stderr"; exit 2 }
    inner = val; sub(/^\[/, "", inner); sub(/\]$/, "", inner)
    n = split(inner, arr, ",")
    for (i = 1; i <= n; i++) { e = dequote(arr[i]); if (e != "") print table "." key "=" e }
  } else {
    print table "." key "=" dequote(val)
  }
  next
}
{ print "parse-toml: unparseable line: " $0 > "/dev/stderr"; exit 2 }
