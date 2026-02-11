* ==============================================================================
* Predicted Probability Panel Plot for 15 Entities - Version 6 (No Blank Titles)
* 3 columns x 5 rows: Nationwide + 14 States
* Model 3b: Including urru##year_centered interaction
* With unadjusted weighted prevalence overlay, legend, and diagnostics
* Date: 2025-10-23
* ==============================================================================

clear all
set more off

* Set working directory
cd "output"

* ==============================================================================
* Define the 15 entities (FIPS codes)
* ==============================================================================

local entity_names `" "Nationwide" "Arizona" "Arkansas" "Colorado" "Georgia" "Iowa" "Kansas" "Maine" "Mississippi" "Missouri" "Montana" "Nebraska" "South Carolina" "Washington" "Wisconsin" "'
local entity_fips "0 4 5 8 13 19 20 23 28 29 30 31 45 53 55"

local n_entities : word count `entity_fips'
di "Processing `n_entities' entities"

local diag_entities "Nationwide Colorado Georgia"

* ==============================================================================
* STEP 1: Loop through entities and create individual plots
* ==============================================================================

local row = 1
foreach fips in `entity_fips' {

    local entity_name : word `row' of `entity_names'
    local show_diag = inlist("`entity_name'", `"`diag_entities'"')

    di ""
    di "{hline 80}"
    di "Processing `row'/15: `entity_name' (FIPS: `fips')"
    di "{hline 80}"

    qui import delimited "../data/combinedbrfss_18_24v10.csv", clear

    if `fips' != 0 {
        qui keep if _state == `fips'
        di "  Observations: " _N
    }
    else {
        di "  Observations (Nationwide): " _N
    }

    qui svyset _psu [pweight=_llcpwt], strata(_ststr)

    di "  Calculating unadjusted prevalence..."
    preserve
    collapse (mean) prev=currentsmoker [pw=_llcpwt], by(year_centered urru)
    if `show_diag' {
        di "  Diagnostic: collapsed prevalence preview for `entity_name'"
        list year_centered urru prev, sepby(urru)
    }
    tempfile prevalence_`row'
    qui save `prevalence_`row''
    restore

    if `show_diag' {
        di "  Running logistic regression (diagnostics shown)..."
        svy: logistic currentsmoker i.urru##c.year_centered i._age_g i.sexvar i._racegr3 i._educag
    }
    else {
        di "  Running logistic regression..."
        qui svy: logistic currentsmoker i.urru##c.year_centered i._age_g i.sexvar i._racegr3 i._educag
    }

    if `show_diag' {
        di "  Calculating margins (diagnostics shown)..."
        margins urru, at(year_centered=(-2(1)4))
    }
    else {
        di "  Calculating margins..."
        qui margins urru, at(year_centered=(-2(1)4))
    }

    matrix results_`row' = r(table)
    matrix pred_mat = r(table)
    if `show_diag' {
        di "  Diagnostic: contents of r(table) for `entity_name'"
        mat list pred_mat
    }
    di "  Results stored"

    local show_ylabel = 0
    local show_xlabel = 0
    if inlist(`row', 1, 4, 7, 10, 13) local show_ylabel = 1
    if `row' >= 13 local show_xlabel = 1

    if `show_ylabel' == 1 {
        local ylabel_opt "ylabel(0(0.05)0.25, angle(0) format(%4.2f) labsize(vsmall))"
    }
    else {
        local ylabel_opt "ylabel(0(0.05)0.25, nolabels noticks)"
    }

    if `show_xlabel' == 1 {
        local xlabel_opt "xlabel(-2 \"2018\" -1 \"2019\" 0 \"2020\" 1 \"2021\" 2 \"2022\" 3 \"2023\" 4 \"2024\", labsize(vsmall))"
    }
    else {
        local xlabel_opt "xlabel(-2 -1 0 1 2 3 4, nolabels noticks)"
    }

    local ytitle_opt ""
    local xtitle_opt ""

    clear
    set obs 14
    gen year_centered = .
    gen urru = .
    gen pred_prob = .
    gen ci_lower = .
    gen ci_upper = .

    local obs = 1
    forvalues yr = -2/4 {
        replace year_centered = `yr' in `obs'
        replace urru = 0 in `obs'
        replace pred_prob = pred_mat[1, `obs'] in `obs'
        replace ci_lower = pred_mat[5, `obs'] in `obs'
        replace ci_upper = pred_mat[6, `obs'] in `obs'
        local obs = `obs' + 1

        replace year_centered = `yr' in `obs'
        replace urru = 1 in `obs'
        replace pred_prob = pred_mat[1, `obs'] in `obs'
        replace ci_lower = pred_mat[5, `obs'] in `obs'
        replace ci_upper = pred_mat[6, `obs'] in `obs'
        local obs = `obs' + 1
    }

    if `show_diag' {
        di "  Diagnostic: prediction rows before merge for `entity_name'"
        list year_centered urru pred_prob ci_lower ci_upper in 1/14, sepby(urru)
    }

    merge 1:1 year_centered urru using `prevalence_`row'', nogenerate

    if `show_diag' {
        di "  Diagnostic: merged dataset snapshot for `entity_name'"
        list year_centered urru pred_prob ci_lower ci_upper prev in 1/14, sepby(urru)
    }

    twoway ///
        (rarea ci_lower ci_upper year_centered if urru==0, fcolor(navy%20) lwidth(none) legend(off)) ///
        (rarea ci_lower ci_upper year_centered if urru==1, fcolor(red%20) lwidth(none) legend(off)) ///
        (line pred_prob year_centered if urru==0, lcolor(navy) lwidth(medium) lpattern(solid) ///
            legend(label(3 "Urban fitted"))) ///
        (line pred_prob year_centered if urru==1, lcolor(red) lwidth(medium) lpattern(dash) ///
            legend(label(4 "Rural fitted"))) ///
        (scatter prev year_centered if urru==0, mcolor(navy) msize(medium) msymbol(O) ///
            legend(label(5 "Urban prevalence"))) ///
        (scatter prev year_centered if urru==1, mcolor(red) msize(medium) msymbol(O) ///
            legend(label(6 "Rural prevalence"))), ///
        title("`entity_name'", size(medsmall) color(black)) ///
        `ytitle_opt' ///
        `xtitle_opt' ///
        `ylabel_opt' ///
        `xlabel_opt' ///
        yscale(range(0 0.25)) ///
        legend(order(3 4 5 6) position(5) ring(0) cols(1) size(vsmall) region(fcolor(white))) ///
        scheme(s2color) ///
        graphregion(color(white) margin(tiny)) ///
        plotregion(margin(small)) ///
        name(graph`row', replace)

    di "  Plot created (graph`row')"
    di "  Completed `row'/15"

    local row = `row' + 1
}

* ==============================================================================
* STEP 2: Combine into 3 columns x 5 rows panel plot
* ==============================================================================

di ""
di "{hline 80}"
di "Creating combined 3 columns x 5 rows panel plot..."
di "{hline 80}"

graph combine graph1 graph2 graph3 ///
              graph4 graph5 graph6 ///
              graph7 graph8 graph9 ///
              graph10 graph11 graph12 ///
              graph13 graph14 graph15, ///
    cols(3) rows(5) ///
    l1title("Predicted Probability", size(small)) ///
    b1title("Year", size(small)) ///
    graphregion(color(white) margin(medium)) ///
    imargin(0.2 0.2 0.2 0.2) ///
    iscale(*0.75) ///
    ysize(11) xsize(8) ///
    name(final_panel, replace)

* ==============================================================================
* STEP 3: Export final plot
* ==============================================================================

di ""
di "Exporting plots..."
graph export "predicted_probs_panel_15states_v6.png", replace width(2400)
graph export "predicted_probs_panel_15states_v6.pdf", replace

di ""
di "{hline 80}"
di "Panel plots saved:"
di "  - predicted_probs_panel_15states_v6.png"
di "  - predicted_probs_panel_15states_v6.pdf"
di "{hline 80}"

