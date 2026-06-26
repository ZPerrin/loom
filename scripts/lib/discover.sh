# scripts/lib/discover.sh — managed-doc discovery for loom (bash 3.2 + awk, no deps).
# Source this, then call the functions below. A doc is "managed" iff it has YAML
# frontmatter containing a `kind:` key (presence, not value-validity). The universe is
# git tracked + staged + untracked (gitignore-respected), read from the working tree, so
# uncommitted docs are visible. Degrades to a bounded find outside a git repo.
# All paths are emitted repo-root-relative.

_DISCOVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

loom_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null && return
  printf '%s\n' "${CLAUDE_PROJECT_DIR:-$PWD}"
}

# raw markdown listing (git-aware, gitignore-respected; bounded find fallback)
_list_md() { # $1=ROOT
  local root="$1"
  if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$root" ls-files --cached --others --exclude-standard -- '*.md'
  else
    ( cd "$root" 2>/dev/null && find . -type f -name '*.md' \
        -not -path '*/.git/*' -not -path '*/node_modules/*' | sed 's|^\./||' )
  fi
}

# exclude path-prefixes from [discovery] exclude in <ROOT>/.loom/loom.toml
doc_excludes() { # $1=ROOT
  local conf="$1/.loom/loom.toml"
  [ -f "$conf" ] || return 0
  awk -f "$_DISCOVER_DIR/parse-toml.awk" "$conf" 2>/dev/null \
    | awk -F= '$1=="discovery.exclude"{sub(/^[^=]*=/,""); print}'
}

_excluded() { # $1=relpath $2=newline-separated exclude prefixes -> 0 if excluded
  local p="$1" e
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    e="${e%/}"   # tolerate a trailing slash in the exclude entry
    case "$p" in "$e"|"$e"/*) return 0 ;; esac
  done <<EOF
$2
EOF
  return 1
}

doc_universe() { # $1=ROOT -> repo-relative *.md, minus [discovery] exclude prefixes
  local root="$1" excl rel
  excl="$(doc_excludes "$root")"
  _list_md "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    _excluded "$rel" "$excl" || printf '%s\n' "$rel"
  done
}

has_kind_frontmatter() { # $1=abs file  -> exit 0 iff frontmatter has a kind: key
  local first
  IFS= read -r first < "$1" 2>/dev/null || return 1
  [ "$first" = "---" ] || return 1
  awk '
    NR==1        { next }            # skip opening ---
    /^---[ \t]*$/ { exit }           # closing --- reached, no kind found
    /^kind:/     { found=1; exit }   # kind key present
    END          { exit (found ? 0 : 1) }
  ' "$1"
}

managed_docs() { # $1=ROOT  -> repo-relative paths of managed docs
  local root="$1" rel
  doc_universe "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    has_kind_frontmatter "$root/$rel" && printf '%s\n' "$rel"
  done
}

omission_candidates() { # $1=ROOT  -> repo-relative *.md lacking kind frontmatter
  local root="$1" rel
  doc_universe "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    has_kind_frontmatter "$root/$rel" || printf '%s\n' "$rel"
  done
}

frontmatter_field() { # $1=abs file  $2=key  -> value (frontmatter block only)
  awk -v k="$2" '
    NR==1        { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    index($0, k ":") == 1 { v=$0; sub(/^[^:]*:[ \t]*/, "", v); print v; exit }
  ' "$1"
}
