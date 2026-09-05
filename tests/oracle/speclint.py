#!/usr/bin/env python3
# Provenance: copied verbatim from the loom spec-grammar oracle
# (scratchpad/oracle/scripts/speclint.py, alongside references/spec-grammar.md).
# Test oracle only — not shipped in the plugin.
"""speclint — lint and slice living-spec markdown files.

Usage:
  speclint.py lint  PATH...  [--json] [--strict]
  speclint.py slice PATH...  [--caps GLOB] [--ids GLOB] [--sections CSV]
                             [--scenarios] [--json]
  speclint.py words

lint   Validate specs/deltas against the grammar (references/spec-grammar.md).
       Exit 0 clean, 1 on errors (or on warnings too, with --strict).
       --json emits findings keyed by rule id + requirement id (telemetry).
slice  Emit a deterministic markdown extract of ratified specs for context
       injection. Same recipe -> same bytes (prompt-cache friendly).
       --sections from: purpose,invariants,requirements,non-goals,drift-log
       (default: purpose,invariants,requirements; scenarios off by default).
words  Print the authoritative banned/flagged word lists.

No dependencies. Python 3.10+.
"""
import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------- word lists
# Authoritative copies. references/writing-rules.md explains the philosophy;
# this file enforces it. Errors = unverifiable/vague (INCOSE-derived).
BANNED = [
    "appropriate", "adequate", "robust", "seamless", "seamlessly",
    "user-friendly", "intuitive", "flexible", "efficient", "efficiently",
    "easy", "easily", "simple", "simply", "quick", "quickly", "timely",
    "comprehensive", "state-of-the-art", "optimal", "optimize", "optimized",
    "maximize", "minimize", "leverage", "leverages", "streamline",
    "sufficient", "reasonable", "as needed", "if possible", "as appropriate",
    "where applicable", "as required", "including but not limited to",
    "etc", "and/or",
]
# Warnings = weak verbs that usually hide the actual behavior.
FLAGGED = [
    "support", "supports", "handle", "handles", "manage", "manages",
    "ensure", "ensures", "enable", "enables", "allow", "allows",
    "facilitate", "facilitates", "improve", "improves", "be able to",
    "various", "several",
]

def _phrase_re(words):
    alts = sorted((re.escape(w) for w in words), key=len, reverse=True)
    return re.compile(r"(?<![\w-])(" + "|".join(alts) + r")(?![\w-])", re.I)

RE_BANNED = _phrase_re(BANNED)
RE_FLAGGED = _phrase_re(FLAGGED)


def check_words(doc, ln, text, rid=None, flagged=False):
    seen = set()
    for m in RE_BANNED.finditer(text):
        if m.group(1).lower() not in seen:
            seen.add(m.group(1).lower())
            doc.add("error", "W001", ln,
                    f"banned word: '{m.group(1)}'", rid)
    if flagged:
        for m in RE_FLAGGED.finditer(text):
            if m.group(1).lower() not in seen:
                seen.add(m.group(1).lower())
                doc.add("warn", "W002", ln,
                        f"weak verb: '{m.group(1)}' — name the observable "
                        f"behavior", rid)

# ------------------------------------------------------------------- grammar
RE_CAP = re.compile(r"^# Capability: ([a-z0-9][a-z0-9-]*)$")
RE_DELTA = re.compile(r"^# Delta: ([a-z0-9][a-z0-9-]*)$")
RE_H2 = re.compile(r"^## (.+)$")
RE_REQ = re.compile(r"^### (R-([A-Z0-9]{2,8})-(\d{3})): (\S.*)$")
RE_REQ_LOOSE = re.compile(r"^### ")
RE_SCEN = re.compile(
    r"^#### Scenario: ([a-z0-9][a-z0-9-]*)(?: (?:→|->) (\S+))?$")
RE_SCEN_LOOSE = re.compile(r"^#### ")
RE_NORM = re.compile(
    r"^(?:WHERE [^,]+, )?(?:WHILE [^,]+, )?(?:WHEN [^,]+, |IF [^,]+, THEN )?"
    r"[Tt]he system (SHALL|MUST) .+\.$")
RE_MODAL = re.compile(r"\b(SHALL|MUST)\b")
RE_SOFT_MODAL = re.compile(r"\b(SHOULD|MAY)\b")
RE_INV = re.compile(r"^- INV-\d+: \S.*\.$")
RE_NG = re.compile(r"^- N-\d+: \S.*\.$")
RE_DRIFT = re.compile(
    r"^- \d{4}-\d{2}-\d{2} (R-[A-Z0-9]{2,8}-\d{3}|INV-\d+): \S.*$")
RE_BULLET = re.compile(r"^- (GIVEN|WHEN|THEN|AND) (\S.*)$")

SPEC_ORDER = ["Purpose", "Invariants", "Requirements", "Non-goals",
              "Drift log"]
SPEC_REQUIRED = {"Purpose", "Requirements"}
DELTA_ORDER = ["Why", "ADDED Requirements", "MODIFIED Requirements",
               "REMOVED Requirements"]
REQ_SECTIONS = {"Requirements", "ADDED Requirements", "MODIFIED Requirements",
                "REMOVED Requirements"}
MAX_NORM_WORDS = 30
MAX_LINE_WORDS = 30
MAX_PURPOSE_SENTENCES = 3
MAX_SCENARIOS = 8
MAX_FILE_LINES = 400


def sentences(text):
    return len([s for s in re.split(r"[.!?]+", text) if s.strip()])


class Doc:
    def __init__(self, path):
        self.path = path
        self.kind = None            # "spec" | "delta"
        self.capability = None
        self.sections = {}          # name -> list[(lineno, text)]
        self.requirements = []      # dicts
        self.findings = []

    def add(self, sev, rule, line, msg, rid=None):
        self.findings.append({"path": str(self.path), "line": line,
                              "severity": sev, "rule": rule, "id": rid,
                              "msg": msg})


def parse(path):
    doc = Doc(path)
    try:
        raw = Path(path).read_text(encoding="utf-8-sig")
    except OSError as e:
        doc.add("error", "G000", 0, f"unreadable: {e}")
        return doc
    lines = raw.replace("\r\n", "\n").split("\n")
    if len(lines) > MAX_FILE_LINES:
        doc.add("warn", "G005", len(lines),
                f"file exceeds {MAX_FILE_LINES} lines; split the capability")

    section = None
    req = None
    scen = None
    order = None
    seen = []
    last_idx = -1

    for i, rawline in enumerate(lines, 1):
        line = rawline.rstrip()
        if not line or line.lstrip().startswith("<!--"):
            continue

        if doc.kind is None:
            m = RE_CAP.match(line)
            d = RE_DELTA.match(line)
            if m:
                doc.kind, doc.capability = "spec", m.group(1)
                order = SPEC_ORDER
            elif d:
                doc.kind, doc.capability = "delta", d.group(1)
                order = DELTA_ORDER
            else:
                doc.add("error", "G001", i,
                        "first line must be '# Capability: <slug>' "
                        "or '# Delta: <capability-slug>'")
                doc.kind, order = "spec", SPEC_ORDER
            continue

        m = RE_H2.match(line)
        if m:
            section = m.group(1)
            req = scen = None
            if section not in order:
                doc.add("error", "G002", i, f"unknown section '## {section}'")
            else:
                idx = order.index(section)
                if idx < last_idx:
                    doc.add("error", "G003", i,
                            f"section '## {section}' out of order")
                last_idx = max(last_idx, idx)
            if section in seen:
                doc.add("error", "G004", i, f"duplicate section '{section}'")
            seen.append(section)
            doc.sections.setdefault(section, [])
            continue

        m = RE_REQ.match(line)
        if m and section in REQ_SECTIONS:
            rid, title = m.group(1), m.group(4)
            req = {"id": rid, "title": title, "line": i, "section": section,
                   "normative": None, "norm_line": None, "scenarios": []}
            scen = None
            doc.requirements.append(req)
            check_words(doc, i, title, rid)
            continue
        if RE_REQ_LOOSE.match(line) and section in REQ_SECTIONS:
            doc.add("error", "R001", i,
                    "requirement header must be "
                    "'### R-<TOKEN>-<NNN>: <Title>'")
            req = scen = None
            continue

        m = RE_SCEN.match(line)
        if m and req is not None:
            scen = {"slug": m.group(1), "test": m.group(2), "line": i,
                    "bullets": []}
            req["scenarios"].append(scen)
            continue
        if RE_SCEN_LOOSE.match(line):
            doc.add("error", "S001", i,
                    "scenario header must be "
                    "'#### Scenario: <slug> -> <test_ref>'",
                    req["id"] if req else None)
            scen = None
            continue

        if scen is not None and line.startswith("- "):
            b = RE_BULLET.match(line)
            if not b:
                doc.add("error", "S001", i,
                        "scenario bullet must start '- GIVEN|WHEN|THEN|AND '",
                        req["id"])
            else:
                scen["bullets"].append((i, b.group(1), b.group(2)))
                check_words(doc, i, b.group(2), req["id"])
            continue

        # a body line inside a requirement, above any scenario -> normative
        if req is not None and scen is None:
            if req["normative"] is None:
                req["normative"], req["norm_line"] = line, i
            else:
                doc.add("error", "R006", i,
                        "requirement body must be exactly one normative "
                        "sentence (move detail to scenarios)", req["id"])
            continue

        doc.sections.setdefault(section or "_preamble", []).append((i, line))

    return doc


def check(doc):
    if doc.kind == "spec":
        for s in SPEC_REQUIRED:
            if s not in doc.sections and not any(
                    r["section"] == s for r in doc.requirements):
                if s == "Requirements" and doc.requirements:
                    continue
                doc.add("error", "G006", 1, f"missing section '## {s}'")
    if doc.kind == "delta" and not doc.requirements and not any(
            s in doc.sections for s in DELTA_ORDER[1:]):
        doc.add("error", "G006", 1,
                "delta needs at least one ADDED/MODIFIED/REMOVED section")

    for name, budget in (("Purpose", MAX_PURPOSE_SENTENCES),
                         ("Why", MAX_PURPOSE_SENTENCES)):
        body = doc.sections.get(name, [])
        text = " ".join(t for _, t in body)
        if body and sentences(text) > budget:
            doc.add("error", "P001", body[0][0],
                    f"'{name}' exceeds {budget} sentences")
        for ln, t in body:
            check_words(doc, ln, t)

    shapes = {"Invariants": (RE_INV, "'- INV-<n>: <sentence>.'"),
              "Non-goals": (RE_NG, "'- N-<n>: <sentence>.'"),
              "Drift log": (RE_DRIFT, "'- YYYY-MM-DD <ID>: <finding>'")}
    for name, (rx, shape) in shapes.items():
        for ln, t in doc.sections.get(name, []):
            if not rx.match(t):
                doc.add("error", "L001", ln, f"line must match {shape}")
            elif name != "Drift log":
                check_words(doc, ln, t, flagged=True)

    tokens = set()
    for r in doc.requirements:
        rid = r["id"]
        tokens.add(rid.split("-")[1])
        removed = r["section"] == "REMOVED Requirements"
        if removed:
            if r["normative"] or r["scenarios"]:
                doc.add("error", "R007", r["line"],
                        "REMOVED block is the header line only", rid)
            continue
        n = r["normative"]
        if n is None:
            doc.add("error", "R002", r["line"],
                    "missing normative sentence", rid)
        else:
            if not RE_NORM.match(n):
                doc.add("error", "R003", r["norm_line"],
                        "normative sentence must fit an EARS shape "
                        "(see references/writing-rules.md)", rid)
            if len(RE_MODAL.findall(n)) != 1:
                doc.add("error", "R004", r["norm_line"],
                        "exactly one SHALL/MUST per requirement", rid)
            if RE_SOFT_MODAL.search(n):
                doc.add("warn", "R005", r["norm_line"],
                        "SHOULD/MAY is non-binding — ratified requirements "
                        "use SHALL/MUST", rid)
            if len(n.split()) > MAX_NORM_WORDS:
                doc.add("error", "R008", r["norm_line"],
                        f"normative sentence exceeds {MAX_NORM_WORDS} words "
                        f"— split the requirement", rid)
            check_words(doc, r["norm_line"], n, rid, flagged=True)
        if len(r["scenarios"]) > MAX_SCENARIOS:
            doc.add("warn", "S004", r["line"],
                    f"more than {MAX_SCENARIOS} scenarios — split the "
                    f"requirement", rid)
        for s in r["scenarios"]:
            kinds = [k for _, k, _ in s["bullets"]]
            if "WHEN" not in kinds or "THEN" not in kinds:
                doc.add("error", "S003", s["line"],
                        "scenario needs at least one WHEN and one THEN", rid)
            if kinds and kinds[0] == "AND":
                doc.add("error", "S001", s["bullets"][0][0],
                        "scenario cannot open with AND", rid)
            if s["test"] is None and doc.kind == "spec":
                doc.add("warn", "S002", s["line"],
                        "no test ref — ratified scenarios should name their "
                        "test", rid)
    if len(tokens) > 1:
        doc.add("error", "R009", 1,
                f"mixed ID tokens in one capability: {sorted(tokens)}")


def lint(paths, as_json, strict):
    docs = [parse(p) for p in paths]
    for d in docs:
        check(d)
    seen = {}
    for d in docs:
        for r in d.requirements:
            if r["section"] == "REMOVED Requirements":
                continue
            key = (r["id"], d.kind)
            if key in seen and d.kind == "spec":
                d.add("error", "R010", r["line"],
                      f"duplicate id {r['id']} (also in {seen[key]})",
                      r["id"])
            seen[key] = d.path
    findings = [f for d in docs for f in d.findings]
    findings.sort(key=lambda f: (f["path"], f["line"]))
    errors = sum(1 for f in findings if f["severity"] == "error")
    warns = len(findings) - errors
    if as_json:
        print(json.dumps({"files": len(docs), "errors": errors,
                          "warnings": warns, "findings": findings}, indent=2))
    else:
        for f in findings:
            rid = f" [{f['id']}]" if f["id"] else ""
            print(f"{f['path']}:{f['line']}: {f['severity']} "
                  f"{f['rule']}{rid}: {f['msg']}")
        print(f"{len(docs)} file(s): {errors} error(s), {warns} warning(s)")
    if errors or (strict and warns):
        return 1
    return 0


def slice_specs(paths, caps, ids, sections, scenarios, as_json):
    docs = [parse(p) for p in paths]
    specs = sorted((d for d in docs if d.kind == "spec"
                    and fnmatch.fnmatch(d.capability or "", caps)),
                   key=lambda d: d.capability or "")
    recipe = (f"caps={caps} ids={ids} sections={','.join(sections)} "
              f"scenarios={'on' if scenarios else 'off'}")
    out = []
    payload = []
    for d in specs:
        reqs = sorted((r for r in d.requirements
                       if fnmatch.fnmatch(r["id"], ids)),
                      key=lambda r: r["id"])
        entry = {"capability": d.capability, "sections": {},
                 "requirements": []}
        block = [f"# Capability: {d.capability}"]
        for name in SPEC_ORDER:
            key = name.lower().replace(" ", "-")
            if key not in sections or name == "Requirements":
                continue
            body = d.sections.get(name)
            if body:
                block.append(f"## {name}")
                block.extend(t for _, t in body)
                entry["sections"][key] = [t for _, t in body]
        if "requirements" in sections and reqs:
            block.append("## Requirements")
            for r in reqs:
                block.append(f"### {r['id']}: {r['title']}")
                if r["normative"]:
                    block.append(r["normative"])
                if scenarios:
                    for s in r["scenarios"]:
                        ref = f" -> {s['test']}" if s["test"] else ""
                        block.append(f"#### Scenario: {s['slug']}{ref}")
                        block.extend(f"- {k} {t}" for _, k, t in s["bullets"])
                entry["requirements"].append(
                    {"id": r["id"], "title": r["title"],
                     "normative": r["normative"],
                     "scenarios": [{"slug": s["slug"], "test": s["test"]}
                                   for s in r["scenarios"]] if scenarios
                     else None})
        out.append("\n".join(block))
        payload.append(entry)
    if as_json:
        print(json.dumps({"recipe": recipe, "capabilities": payload},
                         indent=2))
    else:
        print(f"<!-- slice: {recipe} -->")
        print("\n\n".join(out))
    return 0


def main():
    ap = argparse.ArgumentParser(prog="speclint")
    sub = ap.add_subparsers(dest="cmd", required=True)
    lp = sub.add_parser("lint")
    lp.add_argument("paths", nargs="+")
    lp.add_argument("--json", action="store_true")
    lp.add_argument("--strict", action="store_true")
    sp = sub.add_parser("slice")
    sp.add_argument("paths", nargs="+")
    sp.add_argument("--caps", default="*")
    sp.add_argument("--ids", default="*")
    sp.add_argument("--sections", default="purpose,invariants,requirements")
    sp.add_argument("--scenarios", action="store_true")
    sp.add_argument("--json", action="store_true")
    sub.add_parser("words")
    a = ap.parse_args()
    if a.cmd == "lint":
        sys.exit(lint(a.paths, a.json, a.strict))
    if a.cmd == "slice":
        sys.exit(slice_specs(a.paths, a.caps, a.ids,
                             [s.strip() for s in a.sections.split(",")],
                             a.scenarios, a.json))
    for w in BANNED:
        print(f"error\t{w}")
    for w in FLAGGED:
        print(f"warn\t{w}")


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
