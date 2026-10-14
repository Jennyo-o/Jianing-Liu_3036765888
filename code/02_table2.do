* ============================================================================
* 02_table2.do
* Reproduce Table 2 of Card & Krueger (1994) as a Word document
* (output/tables/table2.docx) using putdocx (built-in, Stata 15+).
*
* Requires: code/01_setup.do has been run first (creates output/ck_clean.dta).
*
* This version does NOT use string matrices. It creates an empty putdocx
* table and fills each cell directly with putdocx table ... = ("text").
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

* --- Parallel lists: variable, scale (100 = share, 1 = level), target row ---
local vars  "chain1 chain2 chain3 chain4 co_owned fte1 pctft1 wage_st w425_1 meal1 hrsopen bonus1 fte2 pctft2 wage_st2 w425_2 w505_2 meal2 hrsopen2 bonus2"
local scals "100 100 100 100 100 1 100 1 100 1 1 100 1 100 1 100 100 1 1 100"
local rows  "3 4 5 6 7 9 10 11 12 13 14 15 17 18 19 20 21 22 23 24"

* ============================================================================
* Build the Word document, filling the table cell by cell.
* ============================================================================
capture mkdir "${ROOT}output/tables"

capture putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("Table 2: Means of Key Variables by State")

* --- Create an empty 24 x 4 table ------------------------------------------
putdocx table tbl2 = (24, 4)

* --- Header and panel titles -----------------------------------------------
putdocx table tbl2(1,1)  = ("Variable")
putdocx table tbl2(1,2)  = ("New Jersey")
putdocx table tbl2(1,3)  = ("Pennsylvania")
putdocx table tbl2(1,4)  = ("t-statistic")
putdocx table tbl2(2,1)  = ("1. Distribution of store types (percent)")
putdocx table tbl2(8,1)  = ("2. Means in wave 1")
putdocx table tbl2(16,1) = ("3. Means in wave 2")

* --- Variable labels (column 1) ---------------------------------------------
putdocx table tbl2(3,1)  = ("Burger King")
putdocx table tbl2(4,1)  = ("KFC")
putdocx table tbl2(5,1)  = ("Roy Rogers")
putdocx table tbl2(6,1)  = ("Wendy's")
putdocx table tbl2(7,1)  = ("Company-owned")
putdocx table tbl2(9,1)  = ("FTE employment")
putdocx table tbl2(10,1) = ("Percentage full-time employees")
putdocx table tbl2(11,1) = ("Starting wage")
putdocx table tbl2(12,1) = ("Wage = \$4.25")
putdocx table tbl2(13,1) = ("Price of full meal")
putdocx table tbl2(14,1) = ("Hours open (weekday)")
putdocx table tbl2(15,1) = ("Recruiting bonus")
putdocx table tbl2(17,1) = ("FTE employment")
putdocx table tbl2(18,1) = ("Percentage full-time employees")
putdocx table tbl2(19,1) = ("Starting wage")
putdocx table tbl2(20,1) = ("Wage = \$4.25")
putdocx table tbl2(21,1) = ("Wage = \$5.05")
putdocx table tbl2(22,1) = ("Price of full meal")
putdocx table tbl2(23,1) = ("Hours open (weekday)")
putdocx table tbl2(24,1) = ("Recruiting bonus")

* --- Data cells (columns 2-4): "mean (SE)" and the Welch t -----------------
forvalues i = 1/20 {
    local v  : word `i' of `vars'
    local sc : word `i' of `scals'
    local r  : word `i' of `rows'

    quietly summarize `v' if state == 1
    local m1 = r(mean) * `sc'
    local s1 = r(sd) / sqrt(r(N)) * `sc'

    quietly summarize `v' if state == 0
    local m2 = r(mean) * `sc'
    local s2 = r(sd) / sqrt(r(N)) * `sc'

    local tt = (`m1' - `m2') / sqrt(`s1'^2 + `s2'^2)

    if `sc' == 100 {
        local njm = trim(string(`m1', "%9.1f"))
        local njs = "(" + trim(string(`s1', "%9.1f")) + ")"
        local pam = trim(string(`m2', "%9.1f"))
        local pas = "(" + trim(string(`s2', "%9.1f")) + ")"
    }
    else {
        local njm = trim(string(`m1', "%9.2f"))
        local njs = "(" + trim(string(`s1', "%9.2f")) + ")"
        local pam = trim(string(`m2', "%9.2f"))
        local pas = "(" + trim(string(`s2', "%9.2f")) + ")"
    }
    local tcell = trim(string(`tt', "%9.2f"))

    putdocx table tbl2(`r',2) = ("`njm'"), linebreak(1)
    putdocx table tbl2(`r',2) = ("`njs'"), append
    putdocx table tbl2(`r',3) = ("`pam'"), linebreak(1)
    putdocx table tbl2(`r',3) = ("`pas'"), append
    putdocx table tbl2(`r',4) = ("`tcell'")
}

putdocx paragraph
putdocx text ("Notes: Standard errors are in parentheses; shares are in percent; t is the Welch (unequal-variance) test.")

putdocx save "${ROOT}output/tables/table2.docx", replace

display as result _n "Wrote ${ROOT}output/tables/table2.docx"
