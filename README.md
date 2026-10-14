# Card & Krueger (1994) — Replication and Independent Extension

This repository replicates **Card, David, and Alan B. Krueger (1994), "Minimum Wages and Employment: A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania," *American Economic Review* 84(4), 772–793**, and adds an independent robustness extension.

The replication reproduces **Tables 2–4 and Figure 1** of the paper from the raw store-level survey data in `01_DID/data/public.csv`, using an independently written Stata pipeline. The extension (Section 5 of the report) tests whether the headline difference-in-differences result is robust to the *composition* of employment. A full write-up — including a validation/limitations discussion and an AI-use disclosure — is in [`replication_report.md`](replication_report.md).

## Repository layout

```
.
├── 01_DID/
│   ├── data/public.csv          # raw store-level survey data (410 obs × 46 cols)
│   ├── DATA_DICTIONARY.md       # column definitions
│   └── README.md                # course data-package notes
├── code/                        # Stata do-files (run in numbered order)
│   ├── 01_setup.do              # clean data → output/ck_clean.dta
│   ├── 02_table2.do             # Table 2 → output/tables/table2.docx
│   ├── 03_figure1.do            # Figure 1 → output/figures/figure1.png
│   ├── 04_table3.do             # Table 3 → output/tables/table3.docx
│   ├── 05_table4.do             # Table 4 → output/tables/table4.docx
│   └── 06_extension.do          # extension → output/tables/table5.docx
├── origianl paper/              # source PDF + manually-adjusted screenshots
├── output/                      # generated artifacts (see below)
│   ├── ck_clean.dta
│   ├── figures/figure1.png
│   └── tables/table2–5.docx
├── run_all.py                   # one-shot: run the whole pipeline
├── verification/verify.py       # optional cross-check (Python, no Stata)
└── replication_report.md        # the empirical report
```

## Requirements

- **Stata 15 or later** (the scripts use `putdocx`, which requires Stata 15+). Developed and tested on **StataNow 19.5 MP** on macOS.
- **Python 3** (standard library only) to run `run_all.py`. The optional `--verify` cross-check additionally needs `numpy` and `pandas`.

## Getting the data

`public.csv` is the restaurant survey data behind the paper, supplied for the course as download package **01** ("Card and Krueger: minimum wage / DID"). Place it at `01_DID/data/public.csv` and keep the filename unchanged. See `01_DID/README.md` and `01_DID/DATA_DICTIONARY.md` for details.

> The raw data is course-restricted. Do not commit it to a public repository; document its location and access requirements instead.

## Reproducing the results

The do-files must be run **in order**: `01_setup.do` first, then any of the remaining scripts. Every script auto-locates the repository root, so it can be run from either the repository root or the `code/` subfolder.

### One-shot run (recommended)

`run_all.py` runs the whole pipeline in order and reports whether each output was produced:

```bash
python3 run_all.py            # generate all tables and figures
python3 run_all.py --verify   # also run the Python cross-check
```

It auto-detects the Stata binary (or accepts `--stata PATH` / a `$STATA` env var) and fails with a clear message if the data file or a do-file is missing.

| Step | Script | Produces |
|---|---|---|
| 1. Clean data | `code/01_setup.do` | `output/ck_clean.dta` |
| 2. Table 2 (means by state) | `code/02_table2.do` | `output/tables/table2.docx` |
| 3. Figure 1 (wage distributions) | `code/03_figure1.do` | `output/figures/figure1.png` |
| 4. Table 3 (employment before/after) | `code/04_table3.do` | `output/tables/table3.docx` |
| 5. Table 4 (reduced-form models) | `code/05_table4.do` | `output/tables/table4.docx` |
| 6. Extension (employment composition) | `code/06_extension.do` | `output/tables/table5.docx` |

### From the Stata GUI

`cd` to the repository root, then `do code/01_setup.do`, `do code/02_table2.do`, and so on.

### From the command line (batch mode)

Run each script with `-b` so Stata writes a batch log to the current directory:

```bash
cd <repository-root>
stata -b do code/01_setup.do
stata -b do code/02_table2.do
stata -b do code/03_figure1.do
stata -b do code/04_table3.do
stata -b do code/05_table4.do
stata -b do code/06_extension.do
```

On macOS with StataNow MP the binary is `stata-mp`:

```bash
/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp -b do code/01_setup.do
```

Batch logs (`*.log`) are written to the working directory and are git-ignored.

## What each script does

- **`01_setup.do`** — imports `public.csv` (lowercasing headers), then builds the derived variables used throughout: full-time-equivalent employment `fte1`/`fte2` (managers + full-time + 0.5 × part-time, with permanent closures set to 0 and temporary closures set to missing), percentage full-time, full-meal price, starting-wage indicators, recruiting bonus, the initial wage gap `gap`, the change in FTE `dfte`, and chain dummies. Saves `output/ck_clean.dta`.

- **`02_table2.do`** — reproduces Table 2: store-type shares and wave-1/wave-2 means by state, with Welch *t*-statistics for the null of equal means (standard errors in parentheses).

- **`03_figure1.do`** — reproduces Figure 1: a 2×2 grid of starting-wage histograms (New Jersey / Pennsylvania × February / November 1992), binned into $0.25 ranges with $4.25 as its own bar, showing New Jersey's mass collapse onto the new $5.05 minimum.

- **`04_table3.do`** — reproduces Table 3: average FTE employment before/after and the changes, by state and by within–New Jersey starting-wage category, including the balanced-sample and temporary-closure sensitivity rows.

- **`05_table4.do`** — reproduces Table 4: five reduced-form regressions of the change in FTE employment on a New Jersey dummy or the initial wage gap, with and without chain/ownership/region controls.

- **`06_extension.do`** — the independent extension: decomposes the change in employment into full-time, part-time, and managers (plus a headcount total), and re-estimates the difference-in-differences for each by **regression** on the New Jersey dummy, with and without chain/ownership controls (heteroskedasticity-robust standard errors).

## Outputs

Generated artifacts live in `output/`:

| Artifact | Description |
|---|---|
| `output/ck_clean.dta` | Cleaned dataset for all downstream scripts |
| `output/tables/table2.docx` | Table 2 replication |
| `output/figures/figure1.png` | Figure 1 replication |
| `output/tables/table3.docx` | Table 3 replication |
| `output/tables/table4.docx` | Table 4 replication |
| `output/tables/table5.docx` | Extension table (employment decomposition) |

## Cross-checking without Stata

`verification/verify.py` recomputes the Table 2 means, standard errors, and *t*-statistics in Python as an independent check of the Stata pipeline (it is not part of the Stata submission):

```bash
python3 verification/verify.py
```

## Report

[`replication_report.md`](replication_report.md) is the empirical report:

1. Research question and motivation
2. Data, sample construction, and variable definitions
3. Empirical design
4. Core replication results and comparison with the original paper
5. Independent extension
6. Validation, limitations, and conclusion
7. AI-use disclosure

The screenshots of the original paper's tables and figure in `origianl paper/` are used for the side-by-side comparisons in Sections 4.1–4.4.

## Known discrepancies with the original paper

Two small, documented differences remain between this replication and the published tables (see the report for detail):

- **"Percentage full-time employees" (Table 2)** is estimated 4–6 points lower in both states and waves — a coding/definition artifact of `public.csv`, not a computational error.
- **Table 4's estimation sample** is 365 stores rather than the paper's 357, because the supplied `public.csv` has slightly more complete wave-2 employment data; the corresponding standard errors are a touch smaller.

Neither affects any point estimate or the substantive conclusion.
