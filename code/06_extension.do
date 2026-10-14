* ============================================================================
* 06_extension.do
* Independent extension (Option 1): robustness of the difference-in-differences
* to the *composition* of employment.
*
* The headline DID (2.75 FTE, NJ-PA) uses FTE = managers + full-time + 0.5 x
* part-time. Here we decompose the change in employment into its components
* (full-time, part-time, managers) and re-estimate the difference-in-differences
* for each, together with an alternative "headcount" total (part-time weighted 1).
* This tests whether the FTE result is driven by a single margin or is spread
* across the components.
*
* The DID is estimated by REGRESSION, not by comparing means: each component's
* change is regressed on the New Jersey dummy, and the coefficient on the dummy
* is the difference-in-differences for that measure. Two specifications are run
* for each measure:
*   (i)  change = a + b*state + e
*   (ii) change = a + b*state + chain2 + chain3 + chain4 + co_owned + e
* Standard errors are heteroskedasticity-robust (HC1), so specification (i)
* is the regression analogue of the Welch (unequal-variance) standard error
* used in Table 3.
*
* (output/tables/table5.docx)
*
* Requires: code/01_setup.do has been run first (creates output/ck_clean.dta).
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

* --- Wave-2 components: same closure handling as fte2 -----------------------
* permanently closed stores (status2==3) -> employment 0;
* temporarily closed / refused (status2 in 0,2,4,5) -> missing.
foreach v in empft2 emppt2 nmgrs2 {
    replace `v' = 0 if status2 == 3
    replace `v' = . if inlist(status2, 0, 2, 4, 5)
}

* --- Component changes (wave 2 - wave 1) ------------------------------------
gen dft   = empft2 - empft                    // full-time employees
gen dpt   = emppt2 - emppt                    // part-time employees
gen dmgr  = nmgrs2 - nmgrs                    // managers
gen dhead = (empft2 + emppt2 + nmgrs2) - (empft + emppt + nmgrs)  // headcount

* --- Regression-based DID for each measure -----------------------------------
* Balanced sample = dfte non-missing (same sample as Table 3, row 4). Because
* dfte is non-missing only when every component is observed in both waves, all
* measures share one sample, so the components add up exactly:
*   DID(FTE)  = DID(full-time) + DID(managers) + 0.5*DID(part-time)
*   DID(head) = DID(full-time) + DID(managers) +     DID(part-time)
* Each DID is the OLS coefficient on the NJ dummy (state).

matrix B1 = J(5, 1, .)   // NJ coefficient, model (i)
matrix S1 = J(5, 1, .)   // robust SE,   model (i)
matrix T1 = J(5, 1, .)   // t = B1 / S1, model (i)
matrix B2 = J(5, 1, .)   // NJ coefficient, model (ii)
matrix S2 = J(5, 1, .)   // robust SE,   model (ii)

local meas "dfte dft dpt dmgr dhead"
forvalues i = 1/5 {
    local v : word `i' of `meas'

    * (i) New Jersey dummy only
    regress `v' state if dfte < ., robust
    matrix B1[`i',1] = _b[state]
    matrix S1[`i',1] = _se[state]
    matrix T1[`i',1] = _b[state] / _se[state]

    * (ii) New Jersey dummy + chain and ownership controls
    regress `v' state chain2 chain3 chain4 co_owned if dfte < ., robust
    matrix B2[`i',1] = _b[state]
    matrix S2[`i',1] = _se[state]
}

* --- Additivity check (should be ~0, up to floating-point rounding) ----------
display as text _n "Additivity check  DID(FTE) - DID(ft) - DID(mgr) - 0.5*DID(pt): " ///
    as result %9.5f (B1[1,1] - B1[2,1] - B1[4,1] - 0.5*B1[3,1])
display as text "Additivity check  DID(head) - DID(ft) - DID(mgr) - DID(pt):   " ///
    as result %9.5f (B1[5,1] - B1[2,1] - B1[4,1] - B1[3,1])

* ============================================================================
* Build the Word document
* ============================================================================
capture mkdir "${ROOT}output/tables"

capture putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("Robustness: Composition of the Difference-in-Differences in Employment")

putdocx table tbl5 = (6, 4)

* --- Header ----------------------------------------------------------------
putdocx table tbl5(1,1) = ("Employment measure (change, waves 1-2)")
putdocx table tbl5(1,2) = ("(i) New Jersey dummy")
putdocx table tbl5(1,3) = ("(ii) New Jersey dummy + controls")
putdocx table tbl5(1,4) = ("t-statistic")

* --- Row labels (column 1) ---------------------------------------------------
putdocx table tbl5(2,1) = ("FTE employment (managers + full-time + half of part-time)")
putdocx table tbl5(3,1) = ("Full-time employees")
putdocx table tbl5(4,1) = ("Part-time employees")
putdocx table tbl5(5,1) = ("Managers")
putdocx table tbl5(6,1) = ("Headcount (managers + full-time + part-time)")

* --- Data cells: coefficient on line 1, robust SE in parentheses on line 2 ----
forvalues i = 1/5 {
    local tr = `i' + 1
    forvalues spec = 1/2 {
        local tc = `spec' + 1
        local m = trim(string(B`spec'[`i',1], "%9.2f"))
        local s = "(" + trim(string(S`spec'[`i',1], "%9.2f")) + ")"
        putdocx table tbl5(`tr', `tc') = ("`m'"), linebreak(1)
        putdocx table tbl5(`tr', `tc') = ("`s'"), append
    }
    local tt = trim(string(T1[`i',1], "%9.2f"))
    putdocx table tbl5(`tr', 4) = ("`tt'")
}

putdocx paragraph
putdocx text ("Notes: Standard errors are shown in parentheses. Each entry is the ordinary-least-squares coefficient on the New Jersey dummy from a regression of the change in that employment measure on the dummy; it is the difference-in-differences for that measure. Column (i) includes only the New Jersey dummy; column (ii) adds controls for chain (KFC, Roy Rogers, Wendy's) and company ownership. Standard errors are heteroskedasticity-robust; column (i) is the regression analogue of the Welch (unequal-variance) standard error of Table 3. The sample is the balanced set of stores with employment data in both waves. FTE employment counts part-time workers as half a full-time worker; headcount counts them as one. Employment at permanently closed stores is set to zero and at temporarily closed stores is treated as missing. The t-statistic is the column (i) coefficient divided by its standard error.")

putdocx save "${ROOT}output/tables/table5.docx", replace

display as result _n "Wrote ${ROOT}output/tables/table5.docx"

* --- Log the estimates for verification --------------------------------------
display as text _n "Difference-in-differences by employment measure (NJ dummy coefficient):"
forvalues i = 1/5 {
    local v : word `i' of `meas'
    display as text "  " "%-14s" "`v'" as result ///
        " (i) " %9.2f B1[`i',1] " (" %9.2f S1[`i',1] ", t = " %9.2f T1[`i',1] ")" ///
        as text "   (ii) " as result %9.2f B2[`i',1] " (" %9.2f S2[`i',1] ")"
}
