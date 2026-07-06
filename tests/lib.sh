# tests/lib.sh — minimal assertion helpers (bash 3.2 safe, no deps).
# Usage: source this, call asserts, end with `finish`.
FAILS=0

assert_eq() { # $1=actual $2=expected $3=label
  if [ "$1" = "$2" ]; then printf '  ok   %s\n' "$3"
  else printf '  FAIL %s\n       expected: [%s]\n       actual:   [%s]\n' "$3" "$2" "$1"; FAILS=$((FAILS+1)); fi
}

assert_contains() { # $1=haystack $2=needle $3=label
  case "$1" in
    *"$2"*) printf '  ok   %s\n' "$3" ;;
    *) printf '  FAIL %s\n       missing: [%s]\n       in:      [%s]\n' "$3" "$2" "$1"; FAILS=$((FAILS+1)) ;;
  esac
}

assert_not_contains() { # $1=haystack $2=needle $3=label
  case "$1" in
    *"$2"*) printf '  FAIL %s\n       unexpected: [%s]\n' "$3" "$2"; FAILS=$((FAILS+1)) ;;
    *) printf '  ok   %s\n' "$3" ;;
  esac
}

assert_exit() { # $1=actual_code $2=expected_code $3=label
  if [ "$1" = "$2" ]; then printf '  ok   %s\n' "$3"
  else printf '  FAIL %s (exit %s, expected %s)\n' "$3" "$1" "$2"; FAILS=$((FAILS+1)); fi
}

test_git_init() {
  git init -q .
  git config core.autocrlf false
}

finish() { # call at end of a test file
  if [ "$FAILS" -ne 0 ]; then printf '%s FAILED\n' "${0##*/}"; exit 1; fi
  printf '%s passed\n' "${0##*/}"
}
