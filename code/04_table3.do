* ============================================================================
* 04_table3.do
* Reproduce Table 3 of Card & Krueger (1994): "Average Employment per Store
* Before and After the Rise in New Jersey Minimum Wage"
* (output/tables/table3.docx) using putdocx (built-in, Stata 15+).
*
* Requires: code/01_setup.do has been run first (creates output/ck_clean.dta).
*
* Table structure (columns):
*   (i) Pennsylvania, (ii) New Jersey, (iii) Difference NJ - PA,
*   (iv) NJ wage = $4.25, (v) NJ wage = $4.26-$4.99, (vi) NJ wage >= $5.00,
*   (vii) low - high, (viii) midrange - high.
* Rows:
*   1-2  mean FTE before / after (all available observations);
*   3    change in mean FTE (row 2 - row 1);
*   4    change in mean FTE over the balanced sample;
*   5    same as row 4, setting FTE at the four temporarily closed stores to 0.
*
* Standard errors are in parentheses. For the change rows (3-5) the standard
* error is the paired standard error of the store-level change (computed on
* stores observed in both waves), matching the paper's t = 2.03 on the 2.76
* difference-in-differences estimate.
* ============================================================================

clear all
set more off

* --- Locate the repository root (see code/01_setup.do) ----------------------
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
            "Set the working directory to the repository root " ///
            "(the folder that contains 01_DID/, code/, and output/)."
        exit 601
    }
}

* --- Load the cleaned dataset ----------------------------------------------
use "${ROOT}output/ck_clean.dta", clear

* --- Wave-2 FTE with temporarily closed stores set to 0 (for row 5) --------
gen fte2t = fte2
replace fte2t = 0 if inlist(status2, 2, 4, 5)
gen dfte_t = fte2t - fte1

* --- Base statistics: BM = means, BS = standard errors (5 groups x 5 rows) --
* Base columns: 1 = PA, 2 = NJ (all), 3 = NJ low ($4.25),
* 4 = NJ mid ($4.26-$4.99), 5 = NJ high (>= $5.00).
matrix BM = J(5, 5, .)
matrix BS = J(5, 5, .)

forvalues g = 0/4 {
    local col = `g' + 1
    if `g' == 0 local cond "state == 0"
    if `g' == 1 local cond "state == 1"
    if `g' == 2 local cond "state == 1 & wage_st == 4.25"
    if `g' == 3 local cond "state == 1 & wage_st > 4.25 & wage_st < 5.00"
    if `g' == 4 local cond "state == 1 & wage_st >= 5.00 & wage_st < ."

    * Row 1: FTE before, all available observations
    quietly summarize fte1 if `cond'
    matrix BM[1, `col'] = r(mean)
    matrix BS[1, `col'] = r(sd) / sqrt(r(N))

    * Row 2: FTE after, all available observations
    quietly summarize fte2 if `cond'
    matrix BM[2, `col'] = r(mean)
    matrix BS[2, `col'] = r(sd) / sqrt(r(N))

    * Row 3: change in mean FTE (row 2 - row 1); SE = paired SE (set below)
    matrix BM[3, `col'] = BM[2, `col'] - BM[1, `col']

    * Row 4: change over the balanced sample (paired SE)
    quietly summarize dfte if `cond' & fte1 < . & fte2 < .
    matrix BM[4, `col'] = r(mean)
    matrix BS[4, `col'] = r(sd) / sqrt(r(N))

    * Row 5: change with temporarily closed stores' FTE set to 0
    quietly summarize dfte_t if `cond' & fte1 < . & fte2t < .
    matrix BM[5, `col'] = r(mean)
    matrix BS[5, `col'] = r(sd) / sqrt(r(N))
}

* Row 3 SE = paired SE (same as row 4, the balanced-sample change)
forvalues col = 1/5 {
    matrix BS[3, `col'] = BS[4, `col']
}

* --- Assemble the 8 table columns from the 5 base columns -------------------
* final cols: 1 PA, 2 NJ, 3 NJ-PA, 4 low, 5 mid, 6 high, 7 low-high, 8 mid-high
matrix M = J(5, 8, .)
matrix S = J(5, 8, .)
forvalues r = 1/5 {
    matrix M[`r', 1] = BM[`r', 1]
    matrix M[`r', 2] = BM[`r', 2]
    matrix M[`r', 3] = BM[`r', 2] - BM[`r', 1]
    matrix M[`r', 4] = BM[`r', 3]
    matrix M[`r', 5] = BM[`r', 4]
    matrix M[`r', 6] = BM[`r', 5]
    matrix M[`r', 7] = BM[`r', 3] - BM[`r', 5]
    matrix M[`r', 8] = BM[`r', 4] - BM[`r', 5]

    matrix S[`r', 1] = BS[`r', 1]
    matrix S[`r', 2] = BS[`r', 2]
    matrix S[`r', 3] = sqrt(BS[`r', 2]^2 + BS[`r', 1]^2)
    matrix S[`r', 4] = BS[`r', 3]
    matrix S[`r', 5] = BS[`r', 4]
    matrix S[`r', 6] = BS[`r', 5]
    matrix S[`r', 7] = sqrt(BS[`r', 3]^2 + BS[`r', 5]^2)
    matrix S[`r', 8] = sqrt(BS[`r', 4]^2 + BS[`r', 5]^2)
}

* ============================================================================
* Build the Word document
* ============================================================================
capture mkdir "${ROOT}output/tables"

capture putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("Table 3: Average Employment per Store Before and After the Rise in New Jersey Minimum Wage")

putdocx table tbl3 = (7, 9)

* --- Row 1: column-group headings (first column of each group) --------------
* Note: putdocx's colspan option errors near the right table edge in this
* Stata version, so the group title sits above the group's first column and
* the remaining header cells are left blank.
putdocx table tbl3(1, 1) = ("")
putdocx table tbl3(1, 2) = ("Stores by state")
putdocx table tbl3(1, 5) = ("Stores in New Jersey")
putdocx table tbl3(1, 8) = ("Differences within NJ")

* --- Row 2: column labels ---------------------------------------------------
putdocx table tbl3(2, 1) = ("Variable")
putdocx table tbl3(2, 2) = ("PA (i)")
putdocx table tbl3(2, 3) = ("NJ (ii)")
putdocx table tbl3(2, 4) = ("Difference, NJ-PA (iii)")
putdocx table tbl3(2, 5) = ("Wage = \$4.25 (iv)")
putdocx table tbl3(2, 6) = ("Wage = \$4.26-\$4.99 (v)")
putdocx table tbl3(2, 7) = ("Wage >= \$5.00 (vi)")
putdocx table tbl3(2, 8) = ("Low-high (vii)")
putdocx table tbl3(2, 9) = ("Midrange-high (viii)")

* --- Row labels (column 1) --------------------------------------------------
putdocx table tbl3(3, 1) = ("1. FTE employment before, all available observations")
putdocx table tbl3(4, 1) = ("2. FTE employment after, all available observations")
putdocx table tbl3(5, 1) = ("3. Change in mean FTE employment")
putdocx table tbl3(6, 1) = ("4. Change in mean FTE employment, balanced sample of stores")
putdocx table tbl3(7, 1) = ("5. Change in mean FTE employment, setting FTE at temporarily closed stores to 0")

* --- Data cells: mean on line 1, SE in parentheses on line 2 ---------------
forvalues r = 1/5 {
    local tr = `r' + 2
    forvalues c = 1/8 {
        local tc = `c' + 1
        local m = trim(string(M[`r', `c'], "%9.2f"))
        local s = "(" + trim(string(S[`r', `c'], "%9.2f")) + ")"
        putdocx table tbl3(`tr', `tc') = ("`m'"), linebreak(1)
        putdocx table tbl3(`tr', `tc') = ("`s'"), append
    }
}

putdocx paragraph
putdocx text ("Notes: Standard errors are shown in parentheses. The sample consists of all stores with available data on employment. FTE employment counts each part-time worker as half a full-time worker. Employment at six closed stores is set to zero; employment at four temporarily closed stores is treated as missing (except in row 5, where it is set to zero). New Jersey stores are classified by wave-1 starting wage: \$4.25 (N = 101), \$4.26-\$4.99 (N = 140), or >= \$5.00 (N = 73).")

putdocx save "${ROOT}output/tables/table3.docx", replace

display as result _n "Wrote ${ROOT}output/tables/table3.docx"

* --- Also print the point estimates for the log / verification --------------
display as text _n "Difference-in-differences (NJ - PA), row 4 (balanced): " ///
    as result %9.2f M[4,3] " (SE " %9.2f S[4,3] ", t = " %9.2f M[4,3]/S[4,3] ")"
display as text "Difference-in-differences (NJ - PA), row 3 (unbalanced): " ///
    as result %9.2f M[3,3] " (SE " %9.2f S[3,3] ", t = " %9.2f M[3,3]/S[3,3] ")"
