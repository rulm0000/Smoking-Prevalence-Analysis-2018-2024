/******************************************************************************
* NATIONWIDE LOGISTIC REGRESSION WITH GEE (CLUSTER-ROBUST SEs)
* Using PROC GENMOD (SAS equivalent of Stata's cluster-robust logit)
* Models 1, 2, 3a, 3b with State Clustering
* Date: 2025-10-21
*
* NOTE: This uses GEE instead of mixed-effects due to convergence issues
*       with 2.7M observations. GEE provides cluster-robust SEs similar
*       to Stata's vce(cluster _state) approach that worked successfully.
******************************************************************************/

/* Set output location */
ods html path="output"
         file="nationwide_genmod_gee_results.html" style=htmlblue;

ods graphics on / reset=all imagename="gee_plot" imagefmt=png width=1200px height=800px;

/******************************************************************************
* STEP 1: IMPORT AND PREPARE DATA (reuse from previous run)
******************************************************************************/

title "Nationwide BRFSS Data Import (2018-2024)";

proc import datafile="data/combinedbrfss_18_24v10.csv"
    out=work.brfss_raw
    dbms=csv
    replace;
    getnames=yes;
run;

data work.brfss_clean;
    set work.brfss_raw;
    if cmiss(currentsmoker, urru, year_centered, _age_g, sexvar, _racegr3, _educag, _state) > 0 then delete;
    year = year_centered + 2020;
    label currentsmoker = "Current Smoker"
          urru = "Urban-Rural Status"
          year_centered = "Year (Centered at 2020)"
          _state = "State FIPS Code";
run;

proc sort data=work.brfss_clean;
    by _state;
run;

title "Data Summary";
proc means data=work.brfss_clean n mean;
    var currentsmoker urru year_centered;
run;

/******************************************************************************
* STEP 2: MODEL 1 - URRU + YEAR_CENTERED with GEE
******************************************************************************/

title "MODEL 1: GEE Logistic Regression with State Clustering";
title2 "DV: Current Smoker | IVs: urru, year_centered | Clustering: State";

proc genmod data=work.brfss_clean descending;
    class _state urru;
    model currentsmoker = urru year_centered / dist=binomial link=logit type3;
    repeated subject=_state / type=exch covb corrw;
    estimate 'Rural vs Urban' urru 1 -1 / exp;
    ods output GEEEmpPEst=model1_params
               GEERCov=model1_rcov
               Type3=model1_type3;
    store work.model1_gee;
run;

/******************************************************************************
* STEP 3: MODEL 2 - MODEL 1 + AGE + SEX + RACE with GEE
******************************************************************************/

title "MODEL 2: GEE Logistic Regression with State Clustering";
title2 "DV: Current Smoker | IVs: urru, year_centered, age, sex, race | Clustering: State";

proc genmod data=work.brfss_clean descending;
    class _state urru _age_g sexvar _racegr3;
    model currentsmoker = urru year_centered _age_g sexvar _racegr3 / dist=binomial link=logit type3;
    repeated subject=_state / type=exch covb corrw;
    estimate 'Rural vs Urban' urru 1 -1 / exp;
    ods output GEEEmpPEst=model2_params
               GEERCov=model2_rcov
               Type3=model2_type3;
    store work.model2_gee;
run;

/******************************************************************************
* STEP 4: MODEL 3a - MODEL 2 + EDUCATION with GEE
******************************************************************************/

title "MODEL 3a: GEE Logistic Regression with State Clustering";
title2 "DV: Current Smoker | IVs: urru, year_centered, age, sex, race, education | Clustering: State";

proc genmod data=work.brfss_clean descending;
    class _state urru _age_g sexvar _racegr3 _educag;
    model currentsmoker = urru year_centered _age_g sexvar _racegr3 _educag / dist=binomial link=logit type3;
    repeated subject=_state / type=exch covb corrw;
    estimate 'Rural vs Urban' urru 1 -1 / exp;
    ods output GEEEmpPEst=model3a_params
               GEERCov=model3a_rcov
               Type3=model3a_type3;
    store work.model3a_gee;
run;

/******************************************************************************
* STEP 5: MODEL 3b - MODEL 3a + URRU*YEAR_CENTERED INTERACTION with GEE
******************************************************************************/

title "MODEL 3b: GEE Logistic Regression WITH INTERACTION and State Clustering";
title2 "DV: Current Smoker | IVs: urru*year_centered, age, sex, race, education | Clustering: State";

proc genmod data=work.brfss_clean descending;
    class _state urru _age_g sexvar _racegr3 _educag;
    model currentsmoker = urru | year_centered _age_g sexvar _racegr3 _educag / dist=binomial link=logit type3;
    repeated subject=_state / type=exch covb corrw;
    estimate 'Rural vs Urban at Year=0' urru 1 -1 / exp;
    estimate 'Interaction Effect' urru*year_centered 1 / exp;
    ods output GEEEmpPEst=model3b_params
               GEERCov=model3b_rcov
               Type3=model3b_type3;
    store work.model3b_gee;
run;

/******************************************************************************
* STEP 6: CALCULATE PREDICTED PROBABILITIES
******************************************************************************/

title "Predicted Probabilities - All Models";

/* Create prediction dataset */
data pred_data;
    do _state = 1;  /* Reference state */
        do urru = 0, 1;
            do year_centered = -2 to 4 by 1;
                year = year_centered + 2020;
                _age_g = 1; sexvar = 1; _racegr3 = 1; _educag = 1;
                output;
            end;
        end;
    end;
run;

/* Get predictions from each model */
proc plm restore=work.model1_gee;
    score data=pred_data out=pred1 predicted=pred_prob1 / ilink;
run;

proc plm restore=work.model2_gee;
    score data=pred_data out=pred2 predicted=pred_prob2 / ilink;
run;

proc plm restore=work.model3a_gee;
    score data=pred_data out=pred3a predicted=pred_prob3a / ilink;
run;

proc plm restore=work.model3b_gee;
    score data=pred_data out=pred3b predicted=pred_prob3b / ilink;
run;

/* Merge predictions */
data all_pred;
    merge pred1(keep=urru year pred_prob1)
          pred2(keep=urru year pred_prob2)
          pred3a(keep=urru year pred_prob3a)
          pred3b(keep=urru year pred_prob3b);
    by urru year;

    if urru = 0 then urru_label = "Urban";
    else urru_label = "Rural";
run;

proc print data=all_pred;
    var urru_label year pred_prob1 pred_prob2 pred_prob3a pred_prob3b;
    title "Predicted Probabilities by Model, Urban/Rural, and Year";
run;

/******************************************************************************
* STEP 7: EXPORT RESULTS TO EXCEL
******************************************************************************/

proc export data=model1_params
    outfile="output/gee_model1_parameters.xlsx"
    dbms=xlsx replace;
run;

proc export data=model2_params
    outfile="output/gee_model2_parameters.xlsx"
    dbms=xlsx replace;
run;

proc export data=model3a_params
    outfile="output/gee_model3a_parameters.xlsx"
    dbms=xlsx replace;
run;

proc export data=model3b_params
    outfile="output/gee_model3b_parameters.xlsx"
    dbms=xlsx replace;
run;

proc export data=all_pred
    outfile="output/gee_predicted_probabilities.xlsx"
    dbms=xlsx replace;
run;

/******************************************************************************
* STEP 8: COMPARISON TO MIXED-EFFECTS APPROACH
******************************************************************************/

title "ANALYSIS SUMMARY";

data _null_;
    file print;
    put "==================================================================================";
    put "NATIONWIDE GEE LOGISTIC REGRESSION ANALYSIS COMPLETE";
    put "==================================================================================";
    put " ";
    put "Approach: GEE (Generalized Estimating Equations)";
    put "Why GEE instead of Mixed-Effects?";
    put "  - PROC GLIMMIX failed to converge with 2.7M observations";
    put "  - Stata melogit also failed (same convergence issue)";
    put "  - GEE provides cluster-robust SEs (equivalent to Stata vce(cluster))";
    put "  - Computationally efficient for large datasets";
    put " ";
    put "Models Estimated:";
    put "  1. Model 1: urru + year_centered";
    put "  2. Model 2: Model 1 + age + sex + race";
    put "  3. Model 3a: Model 2 + education";
    put "  4. Model 3b: Model 3a + urru × year_centered interaction";
    put " ";
    put "Interpretation:";
    put "  - Population-averaged effects (like Stata clustered logit)";
    put "  - Accounts for within-state correlation";
    put "  - Robust standard errors adjusted for clustering";
    put " ";
    put "Results should match Stata clustered logit analysis";
    put "==================================================================================";
run;

ods graphics off;
ods html close;

quit;
