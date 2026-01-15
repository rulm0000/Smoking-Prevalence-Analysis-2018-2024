/*==============================================================================
  CS_QR_finalresults17_fixed_inter.sas

  Logistic Regression Analysis of Smoking Prevalence (2018-2024)

  FIXED VERSION - Captures URRU×year_centered interaction terms in Model 3b

  Key fix: Changed interaction filter from "URRU*year_centered" to "year_centered*URRU"
  (SAS names interactions with continuous variable first when CLASS variable is involved)

  Updates from v16:
  - Uses combinedbrfss_18_24v10.csv (includes 2024 data)
  - Adds nationwide analysis (all states combined)
  - Structured 4-model approach
  - Exports results to CSV for mapping and analysis

  Models:
    1. Basic: URRU + year_centered
    2. Demographics: + age + sex + race
    3. Education: + education
    3b. Interaction: + URRU*year_centered

  Output Files:
  - Excel: output/reports/CS_QR_finalresults17.xlsx
  - CSV: output/tables/logistic_results_summary_v17.csv
  - CSV: output/tables/logistic_or_by_state_v17.csv (for mapping)
==============================================================================*/

/* 1. Import CSV data */
proc import datafile="C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\data\combinedbrfss_18_24v10.csv"
    out=work.CombinedBRFSS_18_24v10
    dbms=csv
    replace;
    getnames=yes;
run;

/* 2. Create analysis dataset - drop rows with missing values in key variables */
data work.analysis_data;
    set work.CombinedBRFSS_18_24v10;

    /* Keep only needed variables */
    keep _STATE _PSU _STSTR _LLCPWT year_centered SEXVAR _AGE_G _RACEGR3 _EDUCAG URRU currentsmoker;

    /* Drop rows with missing values in analysis variables */
    if nmiss(_AGE_G, SEXVAR, _RACEGR3, URRU, currentsmoker, _EDUCAG, _STATE, _LLCPWT, _STSTR, _PSU, year_centered) > 0 then delete;
run;

/* 3. Verify dataset */
proc contents data=work.analysis_data;
    title "Analysis Dataset Contents";
run;

proc means data=work.analysis_data n nmiss min max;
    title "Analysis Dataset Summary";
    var _STATE URRU currentsmoker year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG;
run;

/* 4. Create state lookup table */
data work.state_lookup;
    length State_Code 8 State_Name $30;
    input State_Code State_Name $30.;
    datalines;
0 Nationwide
1 Alabama
2 Alaska
4 Arizona
5 Arkansas
6 California
8 Colorado
9 Connecticut
10 Delaware
11 District_of_Columbia
12 Florida
13 Georgia
15 Hawaii
16 Idaho
17 Illinois
18 Indiana
19 Iowa
20 Kansas
21 Kentucky
22 Louisiana
23 Maine
24 Maryland
25 Massachusetts
26 Michigan
27 Minnesota
28 Mississippi
29 Missouri
30 Montana
31 Nebraska
32 Nevada
33 New_Hampshire
34 New_Jersey
35 New_Mexico
36 New_York
37 North_Carolina
38 North_Dakota
39 Ohio
40 Oklahoma
41 Oregon
42 Pennsylvania
44 Rhode_Island
45 South_Carolina
46 South_Dakota
47 Tennessee
48 Texas
49 Utah
50 Vermont
51 Virginia
53 Washington
54 West_Virginia
55 Wisconsin
56 Wyoming
;
run;

/* 5. Initialize results dataset */
data work.all_results;
    length State_Code 8 State_Name $30 Model $10 Variable $30
           Estimate 8 OR 8 LowerCL_OR 8 UpperCL_OR 8 PValue 8
           Significance $4 OR_Display $20 CI_Display $30;
    stop;
run;

/*==============================================================================
  MACRO: Run logistic models and capture results
==============================================================================*/
%macro run_models(state_code, state_name);

    /* Create WHERE condition */
    %if &state_code = 0 %then %do;
        %let where_clause = ;
    %end;
    %else %do;
        %let where_clause = where _STATE = &state_code;
    %end;

    /*--------------------------------------------------------------------------
      MODEL 1: Basic (URRU + year_centered)
    --------------------------------------------------------------------------*/
    ods select ParameterEstimates;
    ods output ParameterEstimates=work.pe1;

    proc surveylogistic data=work.analysis_data;
        &where_clause;
        class URRU (ref='0') / param=GLM;
        model currentsmoker (event='1') = URRU year_centered;
        weight _LLCPWT;
        strata _STSTR;
        cluster _PSU;
    run;

    /* Process Model 1 results */
    data work.model1_results;
        length State_Code 8 State_Name $30 Model $10 Variable $30
               Estimate 8 OR 8 LowerCL_OR 8 UpperCL_OR 8 PValue 8
               Significance $4 OR_Display $20 CI_Display $30;
        set work.pe1;

        State_Code = &state_code;
        State_Name = "&state_name";
        Model = "1";

        /* Clean and filter variables */
        Variable = strip(Variable);
        if Variable not in ("URRU", "year_centered") then delete;

        /* Calculate OR and CI */
        OR = exp(Estimate);
        LowerCL_OR = exp(Estimate - 1.96*StdErr);
        UpperCL_OR = exp(Estimate + 1.96*StdErr);

        /* Assign significance stars */
        if ProbChiSq < 0.0001 then Significance = '****';
        else if ProbChiSq < 0.001 then Significance = '***';
        else if ProbChiSq < 0.01 then Significance = '**';
        else if ProbChiSq < 0.05 then Significance = '*';
        else Significance = '';

        /* Create display strings */
        OR_Display = trim(put(OR, 6.2)) || trim(Significance);
        CI_Display = "(" || trim(put(LowerCL_OR, 6.2)) || "-" || trim(put(UpperCL_OR, 6.2)) || ")";

        PValue = ProbChiSq;
        keep State_Code State_Name Model Variable Estimate OR LowerCL_OR UpperCL_OR
             PValue Significance OR_Display CI_Display;
    run;

    proc append base=work.all_results data=work.model1_results force;
    run;

    /*--------------------------------------------------------------------------
      MODEL 2: Demographics (+ age, sex, race)
    --------------------------------------------------------------------------*/
    ods select ParameterEstimates;
    ods output ParameterEstimates=work.pe2;

    proc surveylogistic data=work.analysis_data;
        &where_clause;
        class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 / param=GLM;
        model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3;
        weight _LLCPWT;
        strata _STSTR;
        cluster _PSU;
    run;

    /* Process Model 2 results */
    data work.model2_results;
        length State_Code 8 State_Name $30 Model $10 Variable $30
               Estimate 8 OR 8 LowerCL_OR 8 UpperCL_OR 8 PValue 8
               Significance $4 OR_Display $20 CI_Display $30;
        set work.pe2;

        State_Code = &state_code;
        State_Name = "&state_name";
        Model = "2";

        Variable = strip(Variable);
        if Variable not in ("URRU", "year_centered") then delete;

        OR = exp(Estimate);
        LowerCL_OR = exp(Estimate - 1.96*StdErr);
        UpperCL_OR = exp(Estimate + 1.96*StdErr);

        if ProbChiSq < 0.0001 then Significance = '****';
        else if ProbChiSq < 0.001 then Significance = '***';
        else if ProbChiSq < 0.01 then Significance = '**';
        else if ProbChiSq < 0.05 then Significance = '*';
        else Significance = '';

        OR_Display = trim(put(OR, 6.2)) || trim(Significance);
        CI_Display = "(" || trim(put(LowerCL_OR, 6.2)) || "-" || trim(put(UpperCL_OR, 6.2)) || ")";

        PValue = ProbChiSq;
        keep State_Code State_Name Model Variable Estimate OR LowerCL_OR UpperCL_OR
             PValue Significance OR_Display CI_Display;
    run;

    proc append base=work.all_results data=work.model2_results force;
    run;

    /*--------------------------------------------------------------------------
      MODEL 3: Education (+ education)
    --------------------------------------------------------------------------*/
    ods select ParameterEstimates;
    ods output ParameterEstimates=work.pe3;

    proc surveylogistic data=work.analysis_data;
        &where_clause;
        class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=GLM;
        model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG;
        weight _LLCPWT;
        strata _STSTR;
        cluster _PSU;
    run;

    /* Process Model 3 results */
    data work.model3_results;
        length State_Code 8 State_Name $30 Model $10 Variable $30
               Estimate 8 OR 8 LowerCL_OR 8 UpperCL_OR 8 PValue 8
               Significance $4 OR_Display $20 CI_Display $30;
        set work.pe3;

        State_Code = &state_code;
        State_Name = "&state_name";
        Model = "3";

        Variable = strip(Variable);
        if Variable not in ("URRU", "year_centered") then delete;

        OR = exp(Estimate);
        LowerCL_OR = exp(Estimate - 1.96*StdErr);
        UpperCL_OR = exp(Estimate + 1.96*StdErr);

        if ProbChiSq < 0.0001 then Significance = '****';
        else if ProbChiSq < 0.001 then Significance = '***';
        else if ProbChiSq < 0.01 then Significance = '**';
        else if ProbChiSq < 0.05 then Significance = '*';
        else Significance = '';

        OR_Display = trim(put(OR, 6.2)) || trim(Significance);
        CI_Display = "(" || trim(put(LowerCL_OR, 6.2)) || "-" || trim(put(UpperCL_OR, 6.2)) || ")";

        PValue = ProbChiSq;
        keep State_Code State_Name Model Variable Estimate OR LowerCL_OR UpperCL_OR
             PValue Significance OR_Display CI_Display;
    run;

    proc append base=work.all_results data=work.model3_results force;
    run;

    /*--------------------------------------------------------------------------
      MODEL 3b: Interaction (+ URRU*year_centered)
    --------------------------------------------------------------------------*/
    ods select ParameterEstimates;
    ods output ParameterEstimates=work.pe3b;

    proc surveylogistic data=work.analysis_data;
        &where_clause;
        class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=GLM;
        model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
        weight _LLCPWT;
        strata _STSTR;
        cluster _PSU;
    run;

    /* Process Model 3b results */
    data work.model3b_results;
        length State_Code 8 State_Name $30 Model $10 Variable $30
               Estimate 8 OR 8 LowerCL_OR 8 UpperCL_OR 8 PValue 8
               Significance $4 OR_Display $20 CI_Display $30;
        set work.pe3b;

        State_Code = &state_code;
        State_Name = "&state_name";
        Model = "3b";

        Variable = strip(Variable);
        if Variable not in ("URRU", "year_centered", "year_centered*URRU") then delete;

        OR = exp(Estimate);
        LowerCL_OR = exp(Estimate - 1.96*StdErr);
        UpperCL_OR = exp(Estimate + 1.96*StdErr);

        if ProbChiSq < 0.0001 then Significance = '****';
        else if ProbChiSq < 0.001 then Significance = '***';
        else if ProbChiSq < 0.01 then Significance = '**';
        else if ProbChiSq < 0.05 then Significance = '*';
        else Significance = '';

        OR_Display = trim(put(OR, 6.2)) || trim(Significance);
        CI_Display = "(" || trim(put(LowerCL_OR, 6.2)) || "-" || trim(put(UpperCL_OR, 6.2)) || ")";

        PValue = ProbChiSq;
        keep State_Code State_Name Model Variable Estimate OR LowerCL_OR UpperCL_OR
             PValue Significance OR_Display CI_Display;
    run;

    proc append base=work.all_results data=work.model3b_results force;
    run;

%mend run_models;

/*==============================================================================
  RUN ANALYSES
==============================================================================*/

/* Open Excel output file */
ods excel file="C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\output\reports\CS_QR_finalresults17_fixed_inter.xlsx";

/* Run nationwide model first */
%put Running nationwide analysis...;
ods excel options(sheet_name="Nationwide_All_Models");
%run_models(0, Nationwide);

/* Run state-specific models */
%macro run_all_states;
    %do i = 1 %to 56;
        /* Get state name from lookup */
        data _null_;
            set work.state_lookup;
            where State_Code = &i;
            call symputx('state_name', State_Name);
        run;

        /* Skip state codes that don't exist (3, 7, 14, 43, 52) */
        %if &i = 3 or &i = 7 or &i = 14 or &i = 43 or &i = 52 %then %do;
            %put Skipping state code &i (does not exist);
        %end;
        %else %do;
            %put Running analysis for state &i (&state_name)...;
            ods excel options(sheet_name="State_&i._&state_name");
            %run_models(&i, &state_name);
        %end;
    %end;
%mend run_all_states;

%run_all_states;

/* Close Excel file */
ods excel close;

/*==============================================================================
  EXPORT RESULTS TO CSV
==============================================================================*/

/* 1. Master results file with all details */
proc export data=work.all_results
    outfile="C:\Users\ulmcl\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Codex_Jules\output\tables\logistic_results_summary_v17_with_interaction.csv"
    dbms=csv
    replace;
run;

/* 2. Create wide-format file for choropleth mapping (URRU ORs only) */
proc sort data=work.all_results;
    by State_Code Model;
run;

data work.urru_ors;
    set work.all_results;
    Variable = strip(Variable);
    where Variable = "URRU" and Estimate ne 0;  /* Exclude reference level */
    keep State_Code State_Name Model OR LowerCL_OR UpperCL_OR PValue Significance OR_Display CI_Display;
run;

/* Add Model prefix to model numbers for clearer column names */
data work.urru_ors_labeled;
    set work.urru_ors;
    Model_Name = "Model" || strip(Model);
run;

proc transpose data=work.urru_ors_labeled out=work.urru_wide_or(drop=_NAME_);
    by State_Code State_Name;
    id Model_Name;
    var OR;
run;

proc transpose data=work.urru_ors_labeled out=work.urru_wide_pval(drop=_NAME_);
    by State_Code State_Name;
    id Model_Name;
    var PValue;
run;

proc transpose data=work.urru_ors_labeled out=work.urru_wide_sig(drop=_NAME_);
    by State_Code State_Name;
    id Model_Name;
    var Significance;
run;

/* Merge OR, p-value, and significance */
data work.urru_for_mapping;
    merge work.urru_wide_or(rename=(Model1=OR_Model1 Model2=OR_Model2 Model3=OR_Model3 Model3b=OR_Model3b))
          work.urru_wide_pval(rename=(Model1=PValue_Model1 Model2=PValue_Model2 Model3=PValue_Model3 Model3b=PValue_Model3b))
          work.urru_wide_sig(rename=(Model1=Sig_Model1 Model2=Sig_Model2 Model3=Sig_Model3 Model3b=Sig_Model3b));
    by State_Code State_Name;
run;

proc export data=work.urru_for_mapping
    outfile = "C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\output\tables\logistic_or_by_state_v17.csv"
    dbms=csv
    replace;
run;

/*==============================================================================
  PRINT SUMMARY
==============================================================================*/
proc print data=work.all_results(obs=20);
    title "First 20 Results from Logistic Regression Analysis";
run;

proc means data=work.all_results n nmiss min max mean;
    class Model;
    var OR PValue;
    title "Summary Statistics by Model";
run;

%put Analysis complete!;
%put Output files created WITH INTERACTION TERMS:;
%put - Excel: output/reports/CS_QR_finalresults17_with_interaction.xlsx;
%put - CSV (all results): output/tables/logistic_results_summary_v17_with_interaction.csv;
%put - CSV (URRU ORs for mapping): output/tables/logistic_or_by_state_v17.csv;
