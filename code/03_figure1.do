* ============================================================================
* 03_figure1.do
* Reproduce Figure 1 of Card & Krueger (1994): "Distribution of Starting
* Wage Rates" (output/figures/figure1.png).
*
* Four histograms in a 2 x 2 grid:
*   - rows:    February 1992 (wave 1) and November 1992 (wave 2)
*   - columns: New Jersey and Pennsylvania
* Each bar is the percent of stores whose starting wage falls in a wage range.
*
* Starting wages are grouped into $0.25-wide bins, with $4.25 (the old federal
* minimum) kept as its own bar; the bin (5.00, 5.25] contains the new $5.05
* New Jersey minimum, which produces the spike visible in wave 2.
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

* --- Load the cleaned dataset, keep only what Figure 1 needs ---------------
use "${ROOT}output/ck_clean.dta", clear
keep state wage_st wage_st2

* --- Recode starting wages into bins ---------------------------------------
* bin 1 = exactly $4.25; bins 2-8 = successive $0.25 ranges.
foreach v in wage_st wage_st2 {
    gen byte b_`v' = .
    replace b_`v' = 1 if `v' == 4.25
    replace b_`v' = 2 if `v' >  4.25 & `v' <= 4.50
    replace b_`v' = 3 if `v' >  4.50 & `v' <= 4.75
    replace b_`v' = 4 if `v' >  4.75 & `v' <= 5.00
    replace b_`v' = 5 if `v' >  5.00 & `v' <= 5.25
    replace b_`v' = 6 if `v' >  5.25 & `v' <= 5.50
    replace b_`v' = 7 if `v' >  5.50 & `v' <= 5.75
    replace b_`v' = 8 if `v' >  5.75 & `v' <  .
}

* --- Reshape to long: one row per (store, wave), then tabulate ---------------
rename b_wage_st  bin1
rename b_wage_st2 bin2
gen id = _n
reshape long bin, i(id) j(wave)
drop if bin == .
collapse (count) n = id, by(state wave bin)

* --- Fill empty bins with zero so every panel shows all 8 bars ----------------
fillin state wave bin
replace n = 0 if n == .
bysort state wave: egen tot = total(n)
gen pct = 100 * n / tot
drop _fillin tot

* --- Bin labels ---------------------------------------------------------------
label define binlbl 1 "$4.25" 2 "$4.26-4.50" 3 "$4.51-4.75" 4 "$4.76-5.00" ///
    5 "$5.01-5.25" 6 "$5.26-5.50" 7 "$5.51-5.75" 8 "$5.76+"
label values bin binlbl

* --- Common axis options (shared scale so the wave-2 NJ spike is visible) -----
local yopts ylabel(0(20)100, grid gmin gmax) yscale(range(0 100)) ///
    ytitle("Percent of stores", size(small))
local xopts xlabel(1/8, valuelabel labsize(vsmall) angle(45) noticks) xtitle("")

capture mkdir "${ROOT}output/figures"

* --- Panel 1: New Jersey, February 1992 ---------------------------------------
twoway (bar pct bin if state == 1 & wave == 1, ///
        barwidth(1) color(gs6) lcolor(gs0) lwidth(thin)), ///
    `xopts' `yopts' ///
    title("New Jersey", size(medsmall) color(black)) ///
    subtitle("February 1992", size(small) color(gs5)) ///
    scheme(s1color) name(g_nj1, replace)

* --- Panel 2: Pennsylvania, February 1992 -------------------------------------
twoway (bar pct bin if state == 0 & wave == 1, ///
        barwidth(1) color(gs6) lcolor(gs0) lwidth(thin)), ///
    `xopts' `yopts' ///
    title("Pennsylvania", size(medsmall) color(black)) ///
    subtitle("February 1992", size(small) color(gs5)) ///
    scheme(s1color) name(g_pa1, replace)

* --- Panel 3: New Jersey, November 1992 ---------------------------------------
twoway (bar pct bin if state == 1 & wave == 2, ///
        barwidth(1) color(gs6) lcolor(gs0) lwidth(thin)), ///
    `xopts' `yopts' ///
    title("New Jersey", size(medsmall) color(black)) ///
    subtitle("November 1992", size(small) color(gs5)) ///
    scheme(s1color) name(g_nj2, replace)

* --- Panel 4: Pennsylvania, November 1992 -------------------------------------
twoway (bar pct bin if state == 0 & wave == 2, ///
        barwidth(1) color(gs6) lcolor(gs0) lwidth(thin)), ///
    `xopts' `yopts' ///
    title("Pennsylvania", size(medsmall) color(black)) ///
    subtitle("November 1992", size(small) color(gs5)) ///
    scheme(s1color) name(g_pa2, replace)

* --- Combine into the 2 x 2 grid and export -----------------------------------
graph combine g_nj1 g_pa1 g_nj2 g_pa2, ///
    cols(2) rows(2) ///
    title("FIGURE 1. DISTRIBUTION OF STARTING WAGE RATES", size(medsmall)) ///
    xsize(6) ysize(6) ///
    scheme(s1color) name(fig1, replace)

graph export "${ROOT}output/figures/figure1.png", width(1600) replace

display as result _n "Wrote ${ROOT}output/figures/figure1.png"
