# lint-spec.awk — grammar + writing-rule checks for one loom spec doc (bash 3.2 + awk, no deps).
# Port of the living-specs oracle (speclint.py lint) for ratified specs: G/P/R/S/L/W rule families,
# same (rule, line, id) per finding. Delta files (# Delta:) are not linted and produce no output.
# Leading YAML frontmatter (--- … ---) is skipped; reported line numbers are the file's own.
# Usage: awk -v rel=<repo-relative path> [-v json=1] \
#            [-v max_norm_words=30 -v max_line_words=30 -v max_purpose_sentences=3] \
#            [-v max_scenarios=8 -v max_file_lines=400] \
#            [-v extra_banned='p1|p2' -v extra_flagged='w1|w2'] -f lint-spec.awk FILE
# Output: text  <sev>\t<rule>\t<line>\t<rid>\t<message>       sev error|warn; rid may be empty
#         json  {"file":…,"severity":…,"rule":…,"line":N,"id":…,"message":…}   one per line
# Exit 0 always; the caller decides pass/fail. Portable awk (BSD + gawk): no interval quantifiers,
# no \b, no gensub/asort/PROCINFO/length(array). Locale-aware by construction: under a UTF-8 locale
# macOS awk aborts when a regex or tolower() meets a byte that is not a whole character, and its
# substr/length are byte-based, so text is cut with sub() rather than match() offsets, single-byte
# checks are table lookups, and case folding is ASCII-only. Regexes touch whole lines only, which
# still aborts on a file that is not valid UTF-8; run under LC_ALL=C to lint such files bytewise.

BEGIN {
  if (max_norm_words == "") max_norm_words = 30
  if (max_line_words == "") max_line_words = 30   # accepted per contract; the oracle defines but never applies it
  if (max_purpose_sentences == "") max_purpose_sentences = 3
  if (max_scenarios == "") max_scenarios = 8
  if (max_file_lines == "") max_file_lines = 400
  doc_start = 1                                   # first line after frontmatter: where whole-doc findings land

  # Word lists, verbatim from the oracle. W001 errors = vague/unverifiable terms; W002 warnings =
  # weak verbs. Matched longest-first, case-insensitive, not inside a larger word or hyphenation.
  nban = words("appropriate|adequate|robust|seamless|seamlessly|user-friendly|intuitive|flexible" \
               "|efficient|efficiently|easy|easily|simple|simply|quick|quickly|timely|comprehensive" \
               "|state-of-the-art|optimal|optimize|optimized|maximize|minimize|leverage|leverages" \
               "|streamline|sufficient|reasonable|as needed|if possible|as appropriate|where applicable" \
               "|as required|including but not limited to|etc|and/or", BAN, 0)
  nban = words(extra_banned, BAN, nban)
  nflg = words("support|supports|handle|handles|manage|manages|ensure|ensures|enable|enables" \
               "|allow|allows|facilitate|facilitates|improve|improves|be able to|various|several", FLG, 0)
  nflg = words(extra_flagged, FLG, nflg)
  sort_len(BAN, nban); sort_len(FLG, nflg)

  ORDER["Purpose"] = 0; ORDER["Invariants"] = 1; ORDER["Requirements"] = 2
  ORDER["Non-goals"] = 3; ORDER["Drift log"] = 4
  last_idx = -1
  # Sections whose ### blocks parse as requirements. The delta ones are unknown in a spec (G002),
  # but the oracle still parses their blocks, so mirror it.
  REQSEC["Requirements"] = 1; REQSEC["ADDED Requirements"] = 1
  REQSEC["MODIFIED Requirements"] = 1; REQSEC["REMOVED Requirements"] = 1
  for (i = 1; i < 32; i++) CTL[sprintf("%c", i)] = sprintf("\\u%04x", i)
  for (i = 1; i <= 26; i++) LOW[substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", i, 1)] = substr("abcdefghijklmnopqrstuvwxyz", i, 1)
  alnum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"   # \w, ASCII
  for (i = 1; i <= length(alnum); i++) W[substr(alnum, i, 1)] = 1
}

{
  if (NR == 1 && index($0, "\357\273\277") == 1) $0 = substr($0, 1 + length("\357\273\277"))   # UTF-8 BOM
  sub(/[ \t\r\f\v]+$/, "")                                                # rstrip; drops \r too
  if (NR == 1 && $0 == "---") { fm = 1; next }
  if (fm) { if ($0 == "---") { fm = 0; doc_start = NR + 1 }; next }
  if ($0 == "" || $0 ~ /^[ \t]*<!--/) next
  if (kind == "") {                                                       # first content line names the doc
    if ($0 ~ /^# Capability: [a-z0-9][a-z0-9-]*$/) kind = "spec"
    else if ($0 ~ /^# Delta: [a-z0-9][a-z0-9-]*$/) { delta = 1; exit }
    else { add("error", "G001", NR, "", "first line must be '# Capability: <slug>'"); kind = "spec" }   # G001
    next
  }

  if ($0 ~ /^## ./) {
    sec = substr($0, 4); req = 0; scen = 0
    if (!(sec in ORDER)) add("error", "G002", NR, "", "unknown section '## " sec "'")                     # G002: not in the skeleton
    else {
      if (ORDER[sec] < last_idx) add("error", "G003", NR, "", "section '## " sec "' out of order")       # G003: skeleton order
      if (ORDER[sec] > last_idx) last_idx = ORDER[sec]
    }
    if (sec in seen_sec) add("error", "G004", NR, "", "duplicate section '" sec "'")                     # G004
    seen_sec[sec] = 1
    next
  }

  if ((sec in REQSEC) && $0 ~ /^### /) {
    tok = ""
    if ($0 ~ /^### R-[A-Z0-9]+-[0-9][0-9][0-9]: [^ \t]/) {
      id = $0; sub(/^### /, "", id); sub(/: .*$/, "", id)
      tok = id; sub(/^R-/, "", tok); sub(/-.*$/, "", tok)
    }
    if (length(tok) < 2 || length(tok) > 8) {                             # R001: TOKEN is 2–8 chars ({2,8} by length, no intervals)
      add("error", "R001", NR, "", "requirement header must be '### R-<TOKEN>-<NNN>: <Title>'")
      req = 0; scen = 0; next
    }
    req = ++nreq; scen = 0
    R_id[req] = id; R_line[req] = NR; R_sec[req] = sec; R_nline[req] = 0; R_ns[req] = 0
    TOK[tok] = 1
    title = $0; sub(/^### R-[A-Z0-9]+-[0-9][0-9][0-9]: /, "", title)
    check_words(NR, title, id, 0)                                         # W001 on the title
    next
  }

  if ($0 ~ /^#### /) {
    if (req && $0 ~ /^#### Scenario: [a-z0-9][a-z0-9-]*/) {
      rest = $0; sub(/^#### Scenario: [a-z0-9][a-z0-9-]*/, "", rest)
      if (rest == "" || rest ~ /^ (->|→) [^ \t]+$/) {
        scen = ++R_ns[req]
        S_line[req, scen] = NR; S_test[req, scen] = (rest != ""); S_nb[req, scen] = 0
        next
      }
    }
    add("error", "S001", NR, (req ? R_id[req] : ""), "scenario header must be '#### Scenario: <slug> -> <test_ref>'")   # S001
    scen = 0; next
  }

  if (scen && substr($0, 1, 2) == "- ") {
    if ($0 ~ /^- (GIVEN|WHEN|THEN|AND) [^ \t]/) {
      k = $0; sub(/^- /, "", k); sub(/ .*$/, "", k)
      if (++S_nb[req, scen] == 1) { S_k1[req, scen] = k; S_l1[req, scen] = NR }
      if (k == "WHEN") S_when[req, scen] = 1
      if (k == "THEN") S_then[req, scen] = 1
      text = $0; sub(/^- [A-Z]+ /, "", text)
      check_words(NR, text, R_id[req], 0)                                 # W001 on the bullet text
    } else add("error", "S001", NR, R_id[req], "scenario bullet must start '- GIVEN|WHEN|THEN|AND '")   # S001
    next
  }

  if (req && !scen) {                                                     # body line above any scenario = the normative sentence
    if (R_nline[req] == 0) { R_norm[req] = $0; R_nline[req] = NR }
    else add("error", "R006", NR, R_id[req], "requirement body must be exactly one normative sentence (move detail to scenarios)")   # R006
    next
  }

  if (sec != "") { n = ++nb[sec]; BL[sec, n] = NR; BT[sec, n] = $0 }     # section body (preamble is dropped)
}

END {
  if (delta) exit 0
  if (NR > max_file_lines) add("warn", "G005", NR, "", "file exceeds " max_file_lines " lines; split the capability")   # G005: wc -l count
  if (kind == "spec") {
    if (!("Purpose" in seen_sec)) add("error", "G006", doc_start, "", "missing section '## Purpose'")             # G006
    if (!("Requirements" in seen_sec)) add("error", "G006", doc_start, "", "missing section '## Requirements'")

    if (nb["Purpose"] > 0) {                                              # P001: sentence budget over the joined body
      text = ""
      for (i = 1; i <= nb["Purpose"]; i++) text = text (i > 1 ? " " : "") BT["Purpose", i]
      if (sentences(text) > max_purpose_sentences)
        add("error", "P001", BL["Purpose", 1], "", "'Purpose' exceeds " max_purpose_sentences " sentences")
      for (i = 1; i <= nb["Purpose"]; i++) check_words(BL["Purpose", i], BT["Purpose", i], "", 0)
    }

    shape_check("Invariants", "^- INV-[0-9]+: [^ \t].*\\.$", "'- INV-<n>: <sentence>.'")   # L001
    shape_check("Non-goals", "^- N-[0-9]+: [^ \t].*\\.$", "'- N-<n>: <sentence>.'")
    drift_check()

    for (r = 1; r <= nreq; r++) {
      id = R_id[r]
      if (R_sec[r] == "REMOVED Requirements") {                           # R007: never legit in a spec, but the oracle checks it wherever parsed
        if (R_nline[r] || R_ns[r]) add("error", "R007", R_line[r], id, "REMOVED block is the header line only")
        continue
      }
      if (R_nline[r] == 0) add("error", "R002", R_line[r], id, "missing normative sentence")   # R002
      else {
        n = R_norm[r]; ln = R_nline[r]
        if (n !~ /^(WHERE [^,]+, )?(WHILE [^,]+, )?(WHEN [^,]+, |IF [^,]+, THEN )?[Tt]he system (SHALL|MUST) .+\.$/)   # R003: EARS shape
          add("error", "R003", ln, id, "normative sentence must fit an EARS shape (WHERE/WHILE/WHEN/IF …, the system SHALL …)")
        if (nword(n, "SHALL|MUST") != 1) add("error", "R004", ln, id, "exactly one SHALL/MUST per requirement")   # R004
        if (nword(n, "SHOULD|MAY") > 0)                                                                            # R005
          add("warn", "R005", ln, id, "SHOULD/MAY is non-binding — ratified requirements use SHALL/MUST")
        if (split(n, w) > max_norm_words)                                                                          # R008: word budget
          add("error", "R008", ln, id, "normative sentence exceeds " max_norm_words " words — split the requirement")
        check_words(ln, n, id, 1)                                                                                  # W001 + W002
      }
      if (R_ns[r] > max_scenarios)                                                                                 # S004
        add("warn", "S004", R_line[r], id, "more than " max_scenarios " scenarios — split the requirement")
      for (s = 1; s <= R_ns[r]; s++) {
        if (!((r, s) in S_when) || !((r, s) in S_then))                                                            # S003
          add("error", "S003", S_line[r, s], id, "scenario needs at least one WHEN and one THEN")
        if (S_nb[r, s] && S_k1[r, s] == "AND") add("error", "S001", S_l1[r, s], id, "scenario cannot open with AND")   # S001
        if (!S_test[r, s]) add("warn", "S002", S_line[r, s], id, "no test ref — ratified scenarios should name their test")   # S002
      }
    }

    ntok = 0
    for (t in TOK) ntok++
    if (ntok > 1) add("error", "R009", doc_start, "", "mixed ID tokens in one capability: " tok_list())   # R009: one TOKEN per capability
    for (r = 1; r <= nreq; r++) {                                                                        # R010: IDs are permanent and unique
      if (R_sec[r] == "REMOVED Requirements") continue
      id = R_id[r]
      if (id in first) add("error", "R010", R_line[r], id, "duplicate id " id " (first at line " first[id] ")")
      else first[id] = R_line[r]
    }
  }
  emit()
}

function words(s, A, n,   i, m, t) {                 # split a |-list into A[n+1..], lowercased, empties dropped
  m = split(s, t, "|")
  for (i = 1; i <= m; i++) if (t[i] != "") A[++n] = lower(t[i])
  return n
}
function lower(s,   i, n, c, o) {                    # ASCII case fold; other bytes pass through untouched
  o = ""; n = length(s)
  for (i = 1; i <= n; i++) { c = substr(s, i, 1); o = o ((c in LOW) ? LOW[c] : c) }
  return o
}
function sort_len(A, n,   i, j, t) {                 # stable, longest first — the oracle's alternation order
  for (i = 2; i <= n; i++) {
    t = A[i]; j = i - 1
    while (j >= 1 && length(A[j]) < length(t)) { A[j + 1] = A[j]; j-- }
    A[j + 1] = t
  }
}
function sentences(text,   n, i, c, p) {             # pieces between [.!?]+ that hold a non-blank
  n = split(text, p, /[.!?]+/); c = 0
  for (i = 1; i <= n; i++) if (p[i] ~ /[^ \t]/) c++
  return c
}
function nword(s, re,   n, i, c, p, before, after) { # whole-word (\b…\b) occurrences of re in s
  n = split(s, p, re); c = 0                         # p[i] and p[i+1] flank match i; an empty piece between two
  for (i = 1; i < n; i++) {                          # matches means they touch, which is no boundary
    before = (i == 1 && p[1] == "") || (p[i] != "" && !(substr(p[i], length(p[i]), 1) in W))
    after = (i == n - 1 && p[n] == "") || (p[i + 1] != "" && !(substr(p[i + 1], 1, 1) in W))
    if (before && after) c++
  }
  return c
}
function shape_check(name, re, shape,   i) {         # L001 for Invariants / Non-goals; well-shaped lines get word checks
  for (i = 1; i <= nb[name]; i++) {
    if (BT[name, i] !~ re) add("error", "L001", BL[name, i], "", "line must match " shape)
    else check_words(BL[name, i], BT[name, i], "", 1)
  }
}
function drift_check(   i, t, ok, tok) {             # L001 for Drift log: '- YYYY-MM-DD <R-ID|INV-n>: <finding>' (no word checks)
  for (i = 1; i <= nb["Drift log"]; i++) {
    t = BT["Drift log", i]; ok = 0
    if (t ~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] (R-[A-Z0-9]+-[0-9][0-9][0-9]|INV-[0-9]+): [^ \t]/) {
      ok = 1
      if (substr(t, 14, 2) == "R-") { tok = substr(t, 16); sub(/-.*$/, "", tok); ok = (length(tok) >= 2 && length(tok) <= 8) }
    }
    if (!ok) add("error", "L001", BL["Drift log", i], "", "line must match '- YYYY-MM-DD <ID>: <finding>'")
  }
}
function check_words(ln, text, rid, flagged,   lt) { # W001 always, W002 when flagged; each phrase once per line
  lt = lower(text); split("", SEEN)
  scan(ln, text, lt, rid, BAN, nban, "error", "W001", "banned word: '", "'")
  if (flagged) scan(ln, text, lt, rid, FLG, nflg, "warn", "W002", "weak verb: '", "' — name the observable behavior")
}
function edge(c) { return !((c in W) || c == "-") }  # (?<![\w-]) / (?![\w-]): c does not continue a word
function scan(ln, text, lt, rid, P, np, sev, rule, pre, post,   n, i, j, L) {
  n = length(lt); i = 1
  while (i <= n) {
    if (i == 1 || edge(substr(lt, i - 1, 1))) {                           # phrase starts a word
      for (j = 1; j <= np; j++) {
        L = length(P[j])
        if (substr(lt, i, L) == P[j] && edge(substr(lt, i + L, 1))) {     # and ends one
          if (!(P[j] in SEEN)) { SEEN[P[j]] = 1; add(sev, rule, ln, rid, pre substr(text, i, L) post) }
          i += L; break
        }
      }
      if (j <= np) continue
    }
    i++
  }
}
function tok_list(   t, n, i, j, x, a, s) {          # sorted TOKENs for the R009 message
  n = 0
  for (t in TOK) a[++n] = t
  for (i = 2; i <= n; i++) { x = a[i]; j = i - 1; while (j >= 1 && a[j] > x) { a[j + 1] = a[j]; j-- } a[j + 1] = x }
  s = ""
  for (i = 1; i <= n; i++) s = s (i > 1 ? ", " : "") a[i]
  return s
}
function add(sev, rule, ln, rid, msg) {
  nf++; F_sev[nf] = sev; F_rule[nf] = rule; F_line[nf] = ln; F_rid[nf] = rid; F_msg[nf] = msg
}
function jstr(s,   i, c, o, n) {                     # JSON string literal
  o = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c == "\t") o = o "\\t"
    else if (c == "\n") o = o "\\n"
    else if (c == "\r") o = o "\\r"
    else if (c in CTL) o = o CTL[c]
    else o = o c
  }
  return "\"" o "\""
}
function emit(   i, j, k, idx) {                     # stable order by line, as the oracle sorts
  for (i = 1; i <= nf; i++) idx[i] = i
  for (i = 2; i <= nf; i++) {
    k = idx[i]; j = i - 1
    while (j >= 1 && F_line[idx[j]] > F_line[k]) { idx[j + 1] = idx[j]; j-- }
    idx[j + 1] = k
  }
  for (i = 1; i <= nf; i++) {
    k = idx[i]
    if (json) printf "{\"file\":%s,\"severity\":%s,\"rule\":%s,\"line\":%d,\"id\":%s,\"message\":%s}\n", \
                     jstr(rel), jstr(F_sev[k]), jstr(F_rule[k]), F_line[k], jstr(F_rid[k]), jstr(F_msg[k])
    else printf "%s\t%s\t%d\t%s\t%s\n", F_sev[k], F_rule[k], F_line[k], F_rid[k], F_msg[k]
  }
}
