* ============================================================================
* 01_setup.do
* Card & Krueger (1994), AER 84(4): 772-793  --  replication
* Loads public.csv and constructs the derived variables used in
* Tables 2-4 and Figure 1.
* ============================================================================

clear all
set more off

* --- Locate the repository root -------------------------------------------
* public.csv lives at <repo root>/01_DID/data/public.csv. This script works
* whether it is run from the repository root or from the code/ subfolder.
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

* --- Load raw data ---------------------------------------------------------
* public.csv is the store-level survey data (410 obs x 46 cols), downloaded
* from the course website. Uppercase headers are lowercased on import; blank
* cells are read as missing.
import delimited "${ROOT}01_DID/data/public.csv", clear varnames(1) case(lower)

* --- Full-time-equivalent (FTE) employment --------------------------------
* FTE = managers + full-time workers + 0.5 * part-time workers.
gen fte1 = nmgrs + empft + 0.5*emppt
gen fte2 = nmgrs2 + empft2 + 0.5*emppt2

* Wave-2 employment accounting (footnote to Table 2):
*   permanently closed stores (status2==3)          -> employment = 0
*   temporarily closed / renovation / refused
*     (status2 in 0, 2, 4, 5)                       -> employment = missing
replace fte2 = 0 if status2 == 3
replace fte2 = . if inlist(status2, 0, 2, 4, 5)

* --- Percentage full-time employees (fraction of non-managerial staff) -----
gen pctft1 = empft / (empft + emppt)
gen pctft2 = empft2 / (empft2 + emppt2)

* --- Price of a full meal = medium soda + small fries + entree -------------
gen meal1 = psoda + pfry + pentree
gen meal2 = psoda2 + pfry2 + pentree2

* --- Starting-wage indicators ----------------------------------------------
gen w425_1 = (wage_st  == 4.25)
gen w425_2 = (wage_st2 == 4.25)
gen w505_2 = (wage_st2 == 5.05)

* --- Recruiting bonus (wave 1) / special program (wave 2) ------------------
gen bonus1 = bonus
gen bonus2 = special2

* --- Initial wage gap (GAP): proportional increase needed to reach $5.05 ---
* GAP = 0 for Pennsylvania stores, and for NJ stores already paying >= $5.05.
gen gap = 0
replace gap = (5.05 - wage_st)/wage_st if state == 1 & wage_st < 5.05 & wage_st != .

* --- Change in FTE employment ----------------------------------------------
gen dfte = fte2 - fte1

* --- Chain dummies (base category: no dummy) --------------------------------
gen chain1 = (chain == 1)   // Burger King
gen chain2 = (chain == 2)   // KFC
gen chain3 = (chain == 3)   // Roy Rogers
gen chain4 = (chain == 4)   // Wendy's

* --- Save the cleaned dataset for subsequent scripts -----------------------
save "${ROOT}output/ck_clean.dta", replace
