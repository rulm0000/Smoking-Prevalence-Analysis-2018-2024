* ==============================================================================
* Nationwide Logistic Regression Analysis with State Clustering
* Models 1, 2, 3a, 3b with Cluster-Robust Standard Errors
* Using logit with vce(cluster _state)
* Date: 2025-10-21
* ==============================================================================

clear all
set more off

* Set working directory
cd "C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\output"

* Start log file
log using "nationwide_clustered_logit_analysis.log", replace text

* ==============================================================================
* STEP 1: Load nationwide BRFSS data
* ==============================================================================

di ""
di "{hline 80}"
di "LOADING NATIONWIDE BRFSS DATA (2018-2024)"
di "{hline 80}"

import delimited "C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\data\combinedbrfss_18_24v10.csv", clear

* Check data
di ""
di "Total observations: " _N

* Drop missing values
di ""
di "Dropping observations with missing values..."
drop if missing(currentsmoker) | missing(urru) | missing(year_centered) | missing(_age_g) | missing(sexvar) | missing(_racegr3) | missing(_educag) | missing(_state)

di "Observations after dropping missing: " _N

* Create actual year variable
gen year = year_centered + 2020
label variable year "Survey Year"

* Label variables
label variable currentsmoker "Current Smoker"
label variable urru "Urban-Rural Status"
label variable year_centered "Year (centered at 2020)"
label variable _age_g "Age Group"
label variable sexvar "Sex"
label variable _racegr3 "Race/Ethnicity"
label variable _educag "Education Level"

* Create value labels
label define urru_lbl 0 "Urban" 1 "Rural"
label values urru urru_lbl

label define smoker_lbl 0 "Non-smoker" 1 "Current Smoker"
label values currentsmoker smoker_lbl

* Check state distribution
di ""
di "Number of states: "
codebook _state

* ==============================================================================
* STEP 2: Run Model 1 - urru + year_centered
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "MODEL 1: Logistic Regression with Cluster-Robust SEs"
di "DV: Current Smoker"
di "IVs: urru, year_centered"
di "Clustering: State"
di "{hline 80}"
di ""

logit currentsmoker i.urru c.year_centered, vce(cluster _state) or

* Store results
estimates store model1

* Calculate margins for predicted probabilities
di ""
di "Calculating predicted probabilities for Model 1..."
margins urru, at(year_centered=(-2(1)4)) atmeans

* Store margins
matrix model1_margins = r(table)

* ==============================================================================
* STEP 3: Run Model 2 - Model 1 + age + sex + race
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "MODEL 2: Logistic Regression with Cluster-Robust SEs"
di "DV: Current Smoker"
di "IVs: urru, year_centered, age, sex, race"
di "Clustering: State"
di "{hline 80}"
di ""

logit currentsmoker i.urru c.year_centered i._age_g i.sexvar i._racegr3, vce(cluster _state) or

* Store results
estimates store model2

* Calculate margins
di ""
di "Calculating predicted probabilities for Model 2..."
margins urru, at(year_centered=(-2(1)4)) atmeans

* Store margins
matrix model2_margins = r(table)

* ==============================================================================
* STEP 4: Run Model 3a - Model 2 + education
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "MODEL 3a: Logistic Regression with Cluster-Robust SEs"
di "DV: Current Smoker"
di "IVs: urru, year_centered, age, sex, race, education"
di "Clustering: State"
di "{hline 80}"
di ""

logit currentsmoker i.urru c.year_centered i._age_g i.sexvar i._racegr3 i._educag, vce(cluster _state) or

* Store results
estimates store model3a

* Calculate margins
di ""
di "Calculating predicted probabilities for Model 3a..."
margins urru, at(year_centered=(-2(1)4)) atmeans

* Store margins
matrix model3a_margins = r(table)

* ==============================================================================
* STEP 5: Run Model 3b - Model 3a + urru*year_centered interaction
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "MODEL 3b: Logistic Regression WITH INTERACTION and Cluster-Robust SEs"
di "DV: Current Smoker"
di "IVs: urru##year_centered, age, sex, race, education"
di "Clustering: State"
di "{hline 80}"
di ""

logit currentsmoker i.urru##c.year_centered i._age_g i.sexvar i._racegr3 i._educag, vce(cluster _state) or

* Store results
estimates store model3b

* Calculate margins
di ""
di "Calculating predicted probabilities for Model 3b..."
margins urru, at(year_centered=(-2(1)4)) atmeans

* Store margins
matrix model3b_margins = r(table)

* ==============================================================================
* STEP 6: Compare all models
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "MODEL COMPARISON TABLE"
di "{hline 80}"
di ""

estimates table model1 model2 model3a model3b, b(%9.3f) se stats(N ll aic bic)

* ==============================================================================
* STEP 7: Create predicted probability plots for each model
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "CREATING PREDICTED PROBABILITY PLOTS"
di "{hline 80}"
di ""

* Model 1
estimates restore model1
margins urru, at(year_centered=(-2(1)4)) atmeans
marginsplot, ///
    x(year_centered) ///
    recast(line) ///
    recastci(rarea) ///
    ciopts(color(*.3)) ///
    plot1opts(lcolor(navy) lwidth(medium)) ///
    plot2opts(lcolor(cranberry) lwidth(medium)) ///
    ci1opts(fcolor(navy%30) lwidth(none)) ///
    ci2opts(fcolor(cranberry%30) lwidth(none)) ///
    title("Model 1: Urban-Rural + Year", size(medium)) ///
    ytitle("Predicted Probability of Current Smoking", size(small)) ///
    xtitle("Year", size(small)) ///
    xlabel(-2 "2018" -1 "2019" 0 "2020" 1 "2021" 2 "2022" 3 "2023" 4 "2024") ///
    ylabel(, angle(0) format(%4.3f)) ///
    legend(order(1 "Urban" 2 "Rural") position(6) rows(1)) ///
    scheme(s2color) ///
    graphregion(color(white)) ///
    name(model1_plot, replace)

graph export "nationwide_model1_clustered.png", replace width(1200)
graph export "nationwide_model1_clustered.pdf", replace

* Model 2
estimates restore model2
margins urru, at(year_centered=(-2(1)4)) atmeans
marginsplot, ///
    x(year_centered) ///
    recast(line) ///
    recastci(rarea) ///
    ciopts(color(*.3)) ///
    plot1opts(lcolor(navy) lwidth(medium)) ///
    plot2opts(lcolor(cranberry) lwidth(medium)) ///
    ci1opts(fcolor(navy%30) lwidth(none)) ///
    ci2opts(fcolor(cranberry%30) lwidth(none)) ///
    title("Model 2: Model 1 + Age + Sex + Race", size(medium)) ///
    ytitle("Predicted Probability of Current Smoking", size(small)) ///
    xtitle("Year", size(small)) ///
    xlabel(-2 "2018" -1 "2019" 0 "2020" 1 "2021" 2 "2022" 3 "2023" 4 "2024") ///
    ylabel(, angle(0) format(%4.3f)) ///
    legend(order(1 "Urban" 2 "Rural") position(6) rows(1)) ///
    scheme(s2color) ///
    graphregion(color(white)) ///
    name(model2_plot, replace)

graph export "nationwide_model2_clustered.png", replace width(1200)
graph export "nationwide_model2_clustered.pdf", replace

* Model 3a
estimates restore model3a
margins urru, at(year_centered=(-2(1)4)) atmeans
marginsplot, ///
    x(year_centered) ///
    recast(line) ///
    recastci(rarea) ///
    ciopts(color(*.3)) ///
    plot1opts(lcolor(navy) lwidth(medium)) ///
    plot2opts(lcolor(cranberry) lwidth(medium)) ///
    ci1opts(fcolor(navy%30) lwidth(none)) ///
    ci2opts(fcolor(cranberry%30) lwidth(none)) ///
    title("Model 3a: Model 2 + Education", size(medium)) ///
    ytitle("Predicted Probability of Current Smoking", size(small)) ///
    xtitle("Year", size(small)) ///
    xlabel(-2 "2018" -1 "2019" 0 "2020" 1 "2021" 2 "2022" 3 "2023" 4 "2024") ///
    ylabel(, angle(0) format(%4.3f)) ///
    legend(order(1 "Urban" 2 "Rural") position(6) rows(1)) ///
    scheme(s2color) ///
    graphregion(color(white)) ///
    name(model3a_plot, replace)

graph export "nationwide_model3a_clustered.png", replace width(1200)
graph export "nationwide_model3a_clustered.pdf", replace

* Model 3b
estimates restore model3b
margins urru, at(year_centered=(-2(1)4)) atmeans
marginsplot, ///
    x(year_centered) ///
    recast(line) ///
    recastci(rarea) ///
    ciopts(color(*.3)) ///
    plot1opts(lcolor(navy) lwidth(medium)) ///
    plot2opts(lcolor(cranberry) lwidth(medium)) ///
    ci1opts(fcolor(navy%30) lwidth(none)) ///
    ci2opts(fcolor(cranberry%30) lwidth(none)) ///
    title("Model 3b: Model 3a + Urban-Rural × Year Interaction", size(medium)) ///
    ytitle("Predicted Probability of Current Smoking", size(small)) ///
    xtitle("Year", size(small)) ///
    xlabel(-2 "2018" -1 "2019" 0 "2020" 1 "2021" 2 "2022" 3 "2023" 4 "2024") ///
    ylabel(, angle(0) format(%4.3f)) ///
    legend(order(1 "Urban" 2 "Rural") position(6) rows(1)) ///
    scheme(s2color) ///
    graphregion(color(white)) ///
    name(model3b_plot, replace)

graph export "nationwide_model3b_clustered.png", replace width(1200)
graph export "nationwide_model3b_clustered.pdf", replace

* ==============================================================================
* STEP 8: Create combined panel plot
* ==============================================================================

di ""
di "Creating combined panel plot..."

graph combine model1_plot model2_plot model3a_plot model3b_plot, ///
    rows(2) cols(2) ///
    title("Nationwide Predicted Probabilities - Clustered Models", size(medium)) ///
    note("Navy = Urban, Cranberry = Rural. Shaded areas = 95% CIs." ///
         "Cluster-robust SEs by state. Models progressively add covariates.", size(vsmall)) ///
    graphregion(color(white)) ///
    ysize(8) xsize(10) ///
    name(combined_panel, replace)

graph export "nationwide_all_models_clustered_panel.png", replace width(2000)
graph export "nationwide_all_models_clustered_panel.pdf", replace

* ==============================================================================
* STEP 9: Export predicted probabilities to Excel
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "EXPORTING PREDICTED PROBABILITIES TO EXCEL"
di "{hline 80}"

putexcel set "nationwide_clustered_predicted_probs.xlsx", replace

* Headers
putexcel A1 = "Nationwide Predicted Probabilities - Logistic Regression with State Clustering"
putexcel A2 = "Cluster-robust standard errors by state"
putexcel A4 = "Model"
putexcel B4 = "Year"
putexcel C4 = "Urban - Pred Prob"
putexcel D4 = "Urban - SE"
putexcel E4 = "Urban - 95% CI Lower"
putexcel F4 = "Urban - 95% CI Upper"
putexcel G4 = "Rural - Pred Prob"
putexcel H4 = "Rural - SE"
putexcel I4 = "Rural - 95% CI Lower"
putexcel J4 = "Rural - 95% CI Upper"

local excel_row = 5
local model_names "Model 1" "Model 2" "Model 3a" "Model 3b"
local model_list "model1" "model2" "model3a" "model3b"

forvalues m = 1/4 {
    local model_name : word `m' of `model_names'
    local model_short : word `m' of `model_list'

    matrix results = `model_short'_margins

    forvalues yr = 1/7 {
        local year = 2017 + `yr'
        local col_urban = (`yr' - 1) * 2 + 1
        local col_rural = `yr' * 2

        putexcel A`excel_row' = "`model_name'"
        putexcel B`excel_row' = `year'
        putexcel C`excel_row' = results[1, `col_urban']
        putexcel D`excel_row' = results[2, `col_urban']
        putexcel E`excel_row' = results[5, `col_urban']
        putexcel F`excel_row' = results[6, `col_urban']
        putexcel G`excel_row' = results[1, `col_rural']
        putexcel H`excel_row' = results[2, `col_rural']
        putexcel I`excel_row' = results[5, `col_rural']
        putexcel J`excel_row' = results[6, `col_rural']

        local excel_row = `excel_row' + 1
    }
}

di ""
di "Predicted probabilities exported to: nationwide_clustered_predicted_probs.xlsx"

* ==============================================================================
* STEP 10: Summary
* ==============================================================================

di ""
di ""
di "{hline 80}"
di "ANALYSIS COMPLETE - NATIONWIDE CLUSTERED MODELS"
di "{hline 80}"
di ""
di "Models estimated:"
di "  1. Model 1: urru + year_centered"
di "  2. Model 2: Model 1 + age + sex + race"
di "  3. Model 3a: Model 2 + education"
di "  4. Model 3b: Model 3a + urru × year_centered interaction"
di ""
di "All models use logistic regression with cluster-robust standard errors"
di "clustered by state (vce(cluster _state)) to account for state-level clustering."
di ""
di "Outputs created:"
di "  - Individual model plots (PNG & PDF)"
di "  - Combined panel plot (PNG & PDF)"
di "  - Excel file with predicted probabilities"
di ""
di "{hline 80}"

log close
