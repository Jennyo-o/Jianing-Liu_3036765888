---
name: ck-replication-table
description: Generate or regenerate a Card & Krueger (1994) replication table (Word .docx via putdocx) or figure (.png) from the cleaned dataset output/ck_clean.dta. Use whenever asked to add, fix, or re-run one of the paper's tables/figures (Table 2/3/4, Figure 1) or a DID robustness table in this repository.
---

# Card & Krueger replication table/figure workflow

This skill captures the one workflow that was repeated for every table and
figure in this repo. Follow it to produce a new output that is consistent
with the existing do-files (`code/02_table2.do` … `code/06_extension.do`).

## Context (assumed fixed)

- Raw data: `01_DID/data/public.csv` (410 obs × 46 cols; `case(lower)` on import).
- Cleaned data: `output/ck_clean.dta` — produced once by `code/01_setup.do`,
  which builds `fte1`/`fte2` (with closure accounting), `pctft1/2`, `meal1/2`,
  `w425_1/2`, `w505_2`, `bonus1/2`, `gap`, `dfte`, and `chain1`–`chain4`.
- Every downstream do-file loads `output/ck_clean.dta`; **do not re-import the
  CSV or re-derive variables** — add them in `01_setup.do` if needed.
- Outputs go to `output/tables/*.docx` and `output/figures/*.png`.

## Step 1 — Write the do-file from this template

Every table/figure do-file starts with the same scaffold. Copy it and fill in
the middle:

```stata
* ============================================================================
* XX_name.do
* <one-line description of the table/figure and its output path>
*
* Requires: code/01_setup.do has been run first (creates output/ck_clean.dta).
* ============================================================================

clear all
set more off

* --- Locate the repository root (works from root OR from code/) ---------------
capture confirm file "01_DID/data/public.csv"
if _rc == 0 {
    global ROOT ""
}
else {
    capture confirm file "../01_DID/data/public.csv"
    if _rc == 0 {
        global ROOT "../"
    }
    else {
        display as error _n "Cannot find 01_DID/data/public.csv." _n ///
            "Set the working directory to the repository root."
        exit 601
    }
}

use "${ROOT}output/ck_clean.dta", clear

* <compute / regress, store results in matrices or locals>

* <build the putdocx document (see Step 2)>

* <display a verification summary of the key estimates>
```

Notes on the ROOT locator: it must run from either the repo root or `code/`,
because batch logs are written to the current directory and scripts are
sometimes invoked with `do code/XX.do`.

## Step 2 — Emit Word tables with the SE-below-value idiom

The report's convention is **point estimate on line 1, standard error in
parentheses on line 2**. `putdocx` implements this with `linebreak(1)` then
`append`:

```stata
capture mkdir "${ROOT}output/tables"

capture putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("Table X: <title>")

putdocx table tbl = (R, C)              // R rows, C cols

putdocx table tbl(1,1) = ("Variable")   // header row
// ... fill header and row labels ...

// data cell: value then (SE)
local val = trim(string(<matrix-or-local>, "%9.2f"))
local se  = "(" + trim(string(<se>, "%9.2f")) + ")"
putdocx table tbl(r,c) = ("`val'"), linebreak(1)
putdocx table tbl(r,c) = ("`se'"),  append

// loop over a matrix M (rows) and S (standard errors):
forvalues i = 1/`nrows' {
    local tr = `i' + 1
    forvalues c = 1/`ncols' {
        local tc = `c' + 1
        local m = trim(string(M[`i',`c'], "%9.2f"))
        local s = "(" + trim(string(S[`i',`c'], "%9.2f")) + ")"
        putdocx table tbl(`tr',`tc') = ("`m'"), linebreak(1)
        putdocx table tbl(`tr',`tc') = ("`s'"), append
    }
}

putdocx paragraph
putdocx text ("Notes: <sample, definitions, SE type>")

putdocx save "${ROOT}output/tables/tableX.docx", replace
```

Use `%9.2f` for levels/coefficients and `%9.1f` for percent shares (see
`02_table2.do`). For the "—" placeholder (cell not applicable) use a local
`local dash = "—"`.

## Step 3 — Run in Stata batch mode

Run from the repository root; the `*.log` lands in the current directory and is
git-ignored:

```bash
/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp -b do code/XX_name.do
```

(Generic: `stata -b do code/XX_name.do`.) Always re-run after editing; `-b`
also records the full command echo, which is useful for verification.

## Step 4 — Verify before reporting

Follow the same checking discipline used for the existing outputs:

1. **Read the `*.log`.** Confirm the intended sample size (`Number of obs`),
   means, and that nothing silently dropped observations or errored
   (`r(199)`/`r(601)` would appear in the log).
2. **Check internal consistency.** Where a result must satisfy an identity,
   assert it in the do-file. Example (employment decomposition):
   `display DID(FTE) - DID(ft) - DID(mgr) - 0.5*DID(pt)` should be 0.00000.
3. **Compare to the paper.** For reproduced tables, match each coefficient,
   SE, and p-value to the paper's published value (read from the PDF text
   layer or a web source) and trace any discrepancy to its cause rather than
   silently accepting it.
4. **Report the discrepancy, don't hide it.** This repo has two documented
   differences from the paper — the "percentage full-time" coding artifact and
   the 365-vs-357 Table 4 sample — which are called out in the report and
   README rather than "fixed."

## When a new table is needed

- Add the do-file as `code/0N_name.do` (next number after the existing ones).
- Keep the four-part structure (header comment / ROOT locator / computation /
  putdocx + verification `display`).
- Update `README.md` (the script→output table and "What each script does" list)
  and the report's corresponding section, then commit code, output, and report
  together (see the repo's git conventions).
