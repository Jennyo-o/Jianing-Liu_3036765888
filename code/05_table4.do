* ============================================================================
* 05_table4.do
* Reproduce Table 4 of Card & Krueger (1994): "Reduced-Form Models for Change
* in Employment" (output/tables/table4.docx) using putdocx.
*
* Requires: code/01_setup.do has been run first (creates output/ck_clean.dta).
*
* The five models, with dependent variable dfte = fte2 - fte1:
*   (i)   regress dfte state
*   (ii)  regress dfte state chain2 chain3 chain4 co_owned
*   (iii) regress dfte gap
*   (iv)  regress dfte gap chain2 chain3 chain4 co_owned
*   (v)   regress dfte gap chain2 chain3 chain4 co_owned southj centralj pa1 pa2
* where state = New Jersey dummy, gap = initial wage gap to reach $5.05,
* chain2-chain4 = KFC/Roy Rogers/Wendy's (Burger King omitted), co_owned =
* company-owned dummy, and the region dummies are South/Central New Jersey and
* the two eastern Pennsylvania areas (North New Jersey omitted).
*
* The estimation sample is the 357 stores with non-missing change in FTE
* employment and non-missing wave-1 starting wage (needed to form gap).
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

* --- Sample-size diagnostics (log) -----------------------------------------
quietly count if dfte < .
display as text "dfte non-missing:            " as result r(N)
quietly count if wage_st < .
display as text "wage_st non-missing:         " as result r(N)
quietly count if dfte < . & wage_st < .
display as text "dfte & wage_st non-missing:  " as result r(N)
quietly count if dfte < . & wage_st < . & wage_st2 < .
display as text "dfte & wage_st & wage_st2:   " as result r(N)

* --- Dependent-variable summary (log) ----------------------------------------
quietly summarize dfte if dfte < . & wage_st < .
display as text "Mean dfte: " as result %9.3f r(mean) ///
    as text "  SD dfte: " as result %9.3f r(sd)

* ============================================================================
* Run the five reduced-form regressions and store results.
* b# = point estimate, s# = standard error, r# = RMSE, p# = F-test p-value.
* ============================================================================

* Model (i): New Jersey dummy only
regress dfte state if dfte < . & wage_st < .
local b1 = _b[state]
local s1 = _se[state]
local r1 = e(rmse)

* Model (ii): New Jersey dummy + chain and ownership controls
regress dfte state chain2 chain3 chain4 co_owned if dfte < . & wage_st < .
local b2 = _b[state]
local s2 = _se[state]
local r2 = e(rmse)
test chain2 chain3 chain4 co_owned
local p2 = r(p)

* Model (iii): initial wage gap only
regress dfte gap if dfte < . & wage_st < .
local b3 = _b[gap]
local s3 = _se[gap]
local r3 = e(rmse)

* Model (iv): initial wage gap + chain and ownership controls
regress dfte gap chain2 chain3 chain4 co_owned if dfte < . & wage_st < .
local b4 = _b[gap]
local s4 = _se[gap]
local r4 = e(rmse)
test chain2 chain3 chain4 co_owned
local p4 = r(p)

* Model (v): initial wage gap + chain, ownership, and region controls
regress dfte gap chain2 chain3 chain4 co_owned southj centralj pa1 pa2 ///
    if dfte < . & wage_st < .
local b5 = _b[gap]
local s5 = _se[gap]
local r5 = e(rmse)
test chain2 chain3 chain4 co_owned southj centralj pa1 pa2
local p5 = r(p)

* --- Format the strings ------------------------------------------------------
forvalues i = 1/5 {
    local b`i's = trim(string(`b`i'', "%9.2f"))
    local s`i's = "(" + trim(string(`s`i'', "%9.2f")) + ")"
    local r`i's = trim(string(`r`i'', "%9.2f"))
}
local p1s = "—"
local p2s = trim(string(`p2', "%4.2f"))
local p3s = "—"
local p4s = trim(string(`p4', "%4.2f"))
local p5s = trim(string(`p5', "%4.2f"))
local dash = "—"

quietly summarize dfte if dfte < . & wage_st < .
local dvmean = trim(string(r(mean), "%9.3f"))
local dvsd   = trim(string(r(sd), "%9.3f"))
quietly count if dfte < . & wage_st < .
local nest   = r(N)

* ============================================================================
* Build the Word document
* ============================================================================
capture mkdir "${ROOT}output/tables"

capture putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("Table 4: Reduced-Form Models for Change in Employment")

putdocx table tbl4 = (7, 6)

* --- Header ----------------------------------------------------------------
putdocx table tbl4(1,1) = ("Variable")
putdocx table tbl4(1,2) = ("(i)")
putdocx table tbl4(1,3) = ("(ii)")
putdocx table tbl4(1,4) = ("(iii)")
putdocx table tbl4(1,5) = ("(iv)")
putdocx table tbl4(1,6) = ("(v)")

* --- Row labels (column 1) ---------------------------------------------------
putdocx table tbl4(2,1) = ("New Jersey dummy")
putdocx table tbl4(3,1) = ("Initial wage gap")
putdocx table tbl4(4,1) = ("Controls for chain and ownership")
putdocx table tbl4(5,1) = ("Controls for region")
putdocx table tbl4(6,1) = ("Standard error of regression")
putdocx table tbl4(7,1) = ("Probability value for controls")

* --- Row 2: New Jersey dummy (coef in (i),(ii); SE below) --------------------
putdocx table tbl4(2,2) = ("`b1s'"), linebreak(1)
putdocx table tbl4(2,2) = ("`s1s'"), append
putdocx table tbl4(2,3) = ("`b2s'"), linebreak(1)
putdocx table tbl4(2,3) = ("`s2s'"), append
putdocx table tbl4(2,4) = ("`dash'")
putdocx table tbl4(2,5) = ("`dash'")
putdocx table tbl4(2,6) = ("`dash'")

* --- Row 3: initial wage gap (coef in (iii)-(v); SE below) -------------------
putdocx table tbl4(3,2) = ("`dash'")
putdocx table tbl4(3,3) = ("`dash'")
putdocx table tbl4(3,4) = ("`b3s'"), linebreak(1)
putdocx table tbl4(3,4) = ("`s3s'"), append
putdocx table tbl4(3,5) = ("`b4s'"), linebreak(1)
putdocx table tbl4(3,5) = ("`s4s'"), append
putdocx table tbl4(3,6) = ("`b5s'"), linebreak(1)
putdocx table tbl4(3,6) = ("`s5s'"), append

* --- Row 4: controls for chain and ownership --------------------------------
putdocx table tbl4(4,2) = ("no")
putdocx table tbl4(4,3) = ("yes")
putdocx table tbl4(4,4) = ("no")
putdocx table tbl4(4,5) = ("yes")
putdocx table tbl4(4,6) = ("yes")

* --- Row 5: controls for region ---------------------------------------------
putdocx table tbl4(5,2) = ("no")
putdocx table tbl4(5,3) = ("no")
putdocx table tbl4(5,4) = ("no")
putdocx table tbl4(5,5) = ("no")
putdocx table tbl4(5,6) = ("yes")

* --- Row 6: standard error of regression ------------------------------------
putdocx table tbl4(6,2) = ("`r1s'")
putdocx table tbl4(6,3) = ("`r2s'")
putdocx table tbl4(6,4) = ("`r3s'")
putdocx table tbl4(6,5) = ("`r4s'")
putdocx table tbl4(6,6) = ("`r5s'")

* --- Row 7: probability value for controls ----------------------------------
putdocx table tbl4(7,2) = ("`p1s'")
putdocx table tbl4(7,3) = ("`p2s'")
putdocx table tbl4(7,4) = ("`p3s'")
putdocx table tbl4(7,5) = ("`p4s'")
putdocx table tbl4(7,6) = ("`p5s'")

putdocx paragraph
putdocx text ("Notes: Standard errors are shown in parentheses. The sample consists of `nest' stores with available data on employment in waves 1 and 2 and starting wage in wave 1. The dependent variable is the change in FTE employment between waves 1 and 2. The mean (standard deviation) of the dependent variable is `dvmean' (`dvsd'). The probability values test the joint hypothesis that the coefficients on the control variables equal zero.")

putdocx save "${ROOT}output/tables/table4.docx", replace

display as result _n "Wrote ${ROOT}output/tables/table4.docx"

* --- Log the reproduced estimates for verification --------------------------
display as text _n "Reproduced estimates (paper: NJ 2.33/2.30; GAP 15.65/14.92/11.91):"
display as text "NJ dummy:  (i) " as result %9.2f `b1' " (" %9.2f `s1' ")" ///
    as text "  (ii) " as result %9.2f `b2' " (" %9.2f `s2' ")"
display as text "Gap:       (iii) " as result %9.2f `b3' " (" %9.2f `s3' ")" ///
    as text "  (iv) " as result %9.2f `b4' " (" %9.2f `s4' ")" ///
    as text "  (v) " as result %9.2f `b5' " (" %9.2f `s5' ")"
display as text "RMSE:      (i)-(v) " as result %9.2f `r1' " " %9.2f `r2' " " ///
    %9.2f `r3' " " %9.2f `r4' " " %9.2f `r5'
display as text "F p-value: (ii) " as result %4.2f `p2' ///
    as text "  (iv) " as result %4.2f `p4' ///
    as text "  (v) " as result %4.2f `p5'
