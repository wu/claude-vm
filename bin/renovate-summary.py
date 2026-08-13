#!/usr/bin/env python3
"""Summarize a `renovate --platform=local` JSON debug log.

Usage:
    LOG_LEVEL=debug LOG_FORMAT=json RENOVATE_PLATFORM=local renovate | bin/renovate-summary.py
    bin/renovate-summary.py path/to/saved.jsonl
"""
import json
import sys


def find_summary_line(lines):
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if obj.get("msg") == "packageFiles with updates":
            return obj
    return None


def format_update(u):
    label = u.get("updateType", u.get("bucket", "?"))
    return f"{u['newValue']} ({label})"


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as f:
            lines = f.readlines()
    else:
        lines = sys.stdin.readlines()

    summary = find_summary_line(lines)
    if summary is None:
        print(
            "No \"packageFiles with updates\" line found.\n"
            "Make sure the run used LOG_FORMAT=json (LOG_LEVEL=debug alone "
            "prints human-readable text, which this script can't parse).",
            file=sys.stderr,
        )
        sys.exit(1)

    managers = summary.get("config", {})
    any_deps = False
    for manager, package_files in managers.items():
        for pf in package_files:
            deps = pf.get("deps", [])
            if not deps:
                continue
            any_deps = True
            print(f"{pf['packageFile']}  [{manager}]")
            for dep in deps:
                name = dep.get("depName", "?")
                current = dep.get("currentValue", "?")
                skip = dep.get("skipReason")
                updates = dep.get("updates", [])
                if skip:
                    print(f"  {name:<40} {current:<12} skipped: {skip}")
                elif updates:
                    joined = ", ".join(format_update(u) for u in updates)
                    print(f"  {name:<40} {current:<12} -> {joined}")
                else:
                    print(f"  {name:<40} {current:<12} up to date")
            print()

    if not any_deps:
        print("No dependencies extracted.")


if __name__ == "__main__":
    main()
