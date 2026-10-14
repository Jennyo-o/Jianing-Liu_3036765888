#!/usr/bin/env python3
"""
run_all.py — one-shot reproduction of the Card & Krueger (1994) outputs.

Runs the six Stata do-files in order (code/01_setup.do ... code/06_extension.do)
in batch mode and checks that each expected table/figure was produced. This
generates every data-derived output in a single command:

    output/ck_clean.dta              cleaned dataset
    output/tables/table2.docx        Table 2  (means by state)
    output/figures/figure1.png       Figure 1 (wage distributions)
    output/tables/table3.docx        Table 3  (employment before/after)
    output/tables/table4.docx        Table 4  (reduced-form models)
    output/tables/table5.docx        Extension (employment decomposition)

The Markdown report (replication_report.md) references these artifacts but is
assembled separately, because it contains authored prose and manually-adjusted
screenshots of the original paper.

Usage:
    python3 run_all.py [--stata PATH] [--verify]

Options:
    --stata PATH   Path to the Stata binary (default: autodetect).
    --verify       Also run verification/verify.py (requires numpy + pandas).
"""

import argparse
import glob
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))

DATA = "01_DID/data/public.csv"

# (do-file, expected output, human-readable label)
STEPS = [
    ("code/01_setup.do",     "output/ck_clean.dta",        "Clean data"),
    ("code/02_table2.do",    "output/tables/table2.docx",  "Table 2"),
    ("code/03_figure1.do",   "output/figures/figure1.png", "Figure 1"),
    ("code/04_table3.do",    "output/tables/table3.docx",  "Table 3"),
    ("code/05_table4.do",    "output/tables/table4.docx",  "Table 4"),
    ("code/06_extension.do", "output/tables/table5.docx",  "Extension"),
]


def find_stata(cli_path):
    """Locate a runnable Stata binary, or return None."""
    if cli_path:
        if os.path.isfile(cli_path):
            return cli_path
        print(f"error: --stata path not found: {cli_path}", file=sys.stderr)
        return None

    env = os.environ.get("STATA")
    if env and os.path.isfile(env):
        return env

    for name in ("stata-mp", "stata-se", "stata-be", "stata",
                 "StataMP", "StataSE", "StataBE", "Stata"):
        found = shutil.which(name)
        if found:
            return found

    # macOS: Stata ships as a GUI app; the console binary lives in the bundle.
    for pattern in (
        "/Applications/StataNow/*.app/Contents/MacOS/*",
        "/Applications/Stata/*.app/Contents/MacOS/*",
    ):
        for path in sorted(glob.glob(pattern)):
            if os.path.basename(path).lower().startswith("stata"):
                return path

    return None


def main():
    parser = argparse.ArgumentParser(description="Reproduce all CK outputs in one run.")
    parser.add_argument("--stata", help="path to the Stata binary")
    parser.add_argument("--verify", action="store_true",
                        help="also run verification/verify.py (needs numpy + pandas)")
    args = parser.parse_args()

    if not os.path.isfile(os.path.join(ROOT, DATA)):
        print(f"error: data file not found: {DATA}", file=sys.stderr)
        sys.exit(1)

    stata = find_stata(args.stata)
    if not stata:
        print("error: could not locate a Stata binary.", file=sys.stderr)
        print("       pass it explicitly with --stata PATH or set $STATA.",
              file=sys.stderr)
        sys.exit(1)

    print(f"Using Stata: {stata}")
    print(f"Repository:  {ROOT}\n")

    failures = []
    for i, (dofile, output, label) in enumerate(STEPS, start=1):
        do_path = os.path.join(ROOT, dofile)
        if not os.path.isfile(do_path):
            print(f"[{i}/{len(STEPS)}] {label:<12} SKIP  (missing {dofile})")
            failures.append(dofile)
            continue

        print(f"[{i}/{len(STEPS)}] {label:<12} running {dofile} ...", flush=True)
        proc = subprocess.run(
            [stata, "-b", "do", dofile],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

        out_path = os.path.join(ROOT, output)
        log_path = os.path.join(
            ROOT, os.path.splitext(os.path.basename(dofile))[0] + ".log"
        )

        if (proc.returncode != 0
                or not os.path.isfile(out_path)
                or os.path.getsize(out_path) == 0):
            print(f"           FAILED (exit {proc.returncode}); see {log_path}")
            if proc.stdout.strip():
                print(proc.stdout[-2000:])
            failures.append(dofile)
        else:
            print(f"           OK  ->  {output}")

    # Optional independent cross-check (does not touch Stata outputs).
    if args.verify:
        print("\nRunning verification/verify.py ...", flush=True)
        vproc = subprocess.run(
            [sys.executable, "verification/verify.py"],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        print(vproc.stdout)
        if vproc.returncode != 0:
            print("warning: verify.py failed (non-Stata cross-check only)",
                  file=sys.stderr)

    print()
    if failures:
        print(f"DONE with {len(failures)} failure(s): {', '.join(failures)}")
        sys.exit(1)
    print("DONE — all tables and figures generated.")
    print("The report is replication_report.md (references these outputs).")


if __name__ == "__main__":
    main()
