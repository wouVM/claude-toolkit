#!/usr/bin/env python3
"""Size split and diff coverage for a branch, printed as Markdown for a PR description.

Usage (from inside the repo or worktree being measured):
    pr_test_stats.py [--base origin/main] [--category NAME=REGEX ...] [--cov-json coverage.json] [--run]

--base       the ref the branch is compared against; defaults to $PR_BASE, else origin/main.
--category   an extra row for paths matching REGEX (searched anywhere in the path), e.g.
             --category 'Prompts=^prompts/'. Repeatable; checked in the order given, after
             Tests and before Migrations, Docs and Code.
--run        runs the Python suite with coverage first ($PYTEST, default pytest, plus any
             $PYTEST_ARGS such as "-n auto"; writes coverage.json).
--cov-json   reuses an existing coverage.py JSON report instead.
Without --run or --cov-json, only the size split is printed.

"Diff coverage" = of the executable lines this branch ADDED in non-test Python files, how many
ran during the test suite. It is the only coverage number that says something about the change.
It reads coverage.py's JSON format, so it covers Python only; the size split covers any language.
"""
import argparse
import json
import os
import re
import shlex
import subprocess
import sys

BUILTIN_ORDER = ["Code", "Migrations", "Tests", "Docs"]


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def classify(path: str, categories: list) -> str:
    name = os.path.basename(path)
    if (
        re.search(r"(^|/)(tests?|__tests__)/", path)
        or re.match(r"test_.*\.py$", name)
        or re.search(r"_test\.py$", name)
        or name == "conftest.py"
        or re.search(r"\.(test|spec)\.[cm]?[jt]sx?$", name)
    ):
        return "Tests"
    for label, pattern in categories:
        if pattern.search(path):
            return label
    if "/migrations/" in path or path.startswith("migrations/"):
        return "Migrations"
    if path.startswith("docs/") or path.endswith(".md"):
        return "Docs"
    return "Code"


def size_split(base: str, categories: list) -> dict:
    split: dict = {}
    for line in git("diff", "--numstat", f"{base}...HEAD").splitlines():
        added, deleted, path = line.split("\t", 2)
        if added == "-":  # binary
            continue
        row = split.setdefault(classify(path, categories), {"files": 0, "added": 0, "deleted": 0})
        row["files"] += 1
        row["added"] += int(added)
        row["deleted"] += int(deleted)
    return split


def added_lines(base: str, categories: list) -> dict:
    """{path: set(line numbers added)} for Python files classified as Code."""
    out: dict = {}
    current = None
    for line in git("diff", "-U0", f"{base}...HEAD", "--", "*.py").splitlines():
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else None
            current = path if path and classify(path, categories) == "Code" else None
            if current:
                out[current] = set()
            continue
        m = re.match(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@", line)
        if m and current:
            start, count = int(m[1]), int(m[2] or 1)
            out[current].update(range(start, start + count))
    return out


def diff_coverage(base: str, categories: list, cov_json: str):
    with open(cov_json) as fh:
        files = json.load(fh)["files"]
    rows, total, covered = [], 0, 0
    for path, lines in sorted(added_lines(base, categories).items()):
        data = files.get(path)
        if data is None:
            rows.append((path, None, None, []))
            continue
        executed = set(data["executed_lines"])
        statements = lines & (executed | set(data["missing_lines"]))
        hit = statements & executed
        total += len(statements)
        covered += len(hit)
        rows.append((path, len(hit), len(statements), sorted(statements - hit)))
    return rows, covered, total


def ranges(nums: list) -> str:
    out, start, prev = [], None, None
    for n in nums:
        if start is None:
            start = prev = n
        elif n == prev + 1:
            prev = n
        else:
            out.append(f"{start}-{prev}" if start != prev else str(start))
            start = prev = n
    if start is not None:
        out.append(f"{start}-{prev}" if start != prev else str(start))
    return ", ".join(out)


def parse_category(value: str):
    label, sep, pattern = value.partition("=")
    if not sep or not label or not pattern:
        raise argparse.ArgumentTypeError(f"expected NAME=REGEX, got {value!r}")
    if label in BUILTIN_ORDER:
        raise argparse.ArgumentTypeError(f"{label!r} is a built-in category")
    try:
        return label, re.compile(pattern)
    except re.error as exc:
        raise argparse.ArgumentTypeError(f"bad regex {pattern!r}: {exc}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=os.environ.get("PR_BASE", "origin/main"))
    ap.add_argument("--category", action="append", default=[], type=parse_category)
    ap.add_argument("--cov-json")
    ap.add_argument("--run", action="store_true")
    args = ap.parse_args()
    categories = args.category

    try:
        git("rev-parse", "--verify", "--quiet", f"{args.base}^{{commit}}")
    except subprocess.CalledProcessError:
        print(f"Base ref {args.base!r} not found. Fetch it, or pass --base / set PR_BASE.", file=sys.stderr)
        return 2

    cov_json = args.cov_json
    suite_failed = False
    if args.run:
        cov_json = cov_json or "coverage.json"
        pytest = os.environ.get("PYTEST", "pytest")
        extra = shlex.split(os.environ.get("PYTEST_ARGS", ""))
        result = subprocess.run(
            [pytest, *extra, "-q", "-p", "no:cacheprovider", "--cov=.",
             f"--cov-report=json:{cov_json}", "--cov-report="],
            check=False,
        )
        suite_failed = result.returncode != 0

    split = size_split(args.base, categories)
    order = ["Code", "Migrations", *[label for label, _ in categories], "Tests", "Docs"]
    print("| Part | Files | Lines added | Lines removed |")
    print("|---|---|---|---|")
    for key in dict.fromkeys(order):
        if key in split:
            r = split[key]
            print(f"| {key} | {r['files']} | {r['added']:,} | {r['deleted']:,} |")
    code = split.get("Code", {}).get("added", 0)
    tests = split.get("Tests", {}).get("added", 0)
    if code:
        print(f"\nTest lines per code line: {tests / code:.1f}")

    if cov_json and os.path.exists(cov_json):
        rows, covered, total = diff_coverage(args.base, categories, cov_json)
        pct = 100 * covered / total if total else 100.0
        print(f"\nDiff coverage (changed code lines run by the suite): {covered}/{total} = {pct:.0f}%")
        if suite_failed:
            # Crashed workers or aborted runs drop their coverage data, so the number undercounts.
            print("\nWARNING: the suite did not pass cleanly; this number undercounts. Rerun before quoting it.")
        uncovered = [(p, m) for p, _, _, m in rows if m]
        unmeasured = [p for p, h, _, _ in rows if h is None]
        if uncovered:
            print("\nUncovered changed lines:")
            for path, missing in uncovered:
                print(f"- `{path}`: {ranges(missing)}")
        if unmeasured:
            print("\nNot measured (no coverage data): " + ", ".join(f"`{p}`" for p in unmeasured))
    return 0


if __name__ == "__main__":
    sys.exit(main())
