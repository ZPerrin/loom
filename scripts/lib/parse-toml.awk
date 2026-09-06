# parse-toml.awk — emit normalized "table.key=value" lines for loom's TOML subset.
# One line per scalar; one line per array element (repeated key). Exit 2 on any
# unsupported construct (array-of-tables, inline table, multiline, unparseable).
# Subset limits: single-line arrays only; a comma inside a quoted element stays in it.
function strip(s) { sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
function dequote(s) {
  s = strip(s)
  if (s ~ /^".*"$/) s = substr(s, 2, length(s) - 2)
  return s
}
function split_elems(s, arr,   i, c, inq, n, cur) {   # split on commas outside quotes
  n = 0; cur = ""; inq = 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\"") { inq = !inq; cur = cur c; continue }
    if (c == "," && !inq) { arr[++n] = cur; cur = ""; continue }
    cur = cur c
  }
  arr[++n] = cur
  return n
}
function strip_comment(s,   i, c, inq, out) {
  inq = 0; out = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\"") { inq = !inq; out = out c; continue }
    if (c == "#" && !inq) break
    out = out c
  }
  sub(/[ \t\r]+$/, "", out)
  return out
}
{ sub(/\r$/, "", $0); $0 = strip_comment($0) }
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
    n = split_elems(inner, arr)
    for (i = 1; i <= n; i++) { e = dequote(arr[i]); if (e != "") print table "." key "=" e }
  } else {
    print table "." key "=" dequote(val)
  }
  next
}
{ print "parse-toml: unparseable line: " $0 > "/dev/stderr"; exit 2 }
