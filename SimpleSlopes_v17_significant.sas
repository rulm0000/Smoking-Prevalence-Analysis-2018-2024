/*================================================================================
  SimpleSlopes_v17_significant.sas

  Simple-slope ORs for year_centered by URRU level for states with significant
  URRU*year_centered interactions (plus nationwide analysis).

  Based on: SimpleSlopes6.9.25.sas
  Updated for: combinedbrfss_18_24v10.csv (2018-2024 data)

  States: 15 with significant interactions + nationwide (0)
================================================================================*/

/* Import CSV data */
proc import datafile="data/combinedbrfss_18_24v10.csv"
    out=work.CombinedBRFSS_18_24v10
    dbms=csv
    replace;
    getnames=yes;
run;

/* Create analysis dataset */
data work.analysis_data;
    set work.CombinedBRFSS_18_24v10;
    keep _STATE _PSU _STSTR _LLCPWT year_centered SEXVAR _AGE_G _RACEGR3 _EDUCAG URRU currentsmoker;
    if nmiss(_AGE_G, SEXVAR, _RACEGR3, URRU, currentsmoker, _EDUCAG, _STATE, _LLCPWT, _STSTR, _PSU, year_centered) > 0 then delete;
run;

/* List of states with significant interactions + nationwide (0) */
%let statelist = 0 4 5 8 13 19 20 23 28 29 30 31 45 53 55;

/* State names for labeling */
%let state_0 = Nationwide;
%let state_4 = Arizona;
%let state_5 = Arkansas;
%let state_8 = Colorado;
%let state_13 = Georgia;
%let state_19 = Iowa;
%let state_20 = Kansas;
%let state_23 = Maine;
%let state_28 = Mississippi;
%let state_29 = Missouri;
%let state_30 = Montana;
%let state_31 = Nebraska;
%let state_45 = South_Carolina;
%let state_53 = Washington;
%let state_55 = Wisconsin;

/* Empty the final output set in case it exists */
proc datasets lib=work nolist;
    delete YearSlopes_All;
quit;

/* Macro loop for simple slopes */
%macro SimpleSlopes;
    %local i st statename;
    %do i = 1 %to %sysfunc(countw(&statelist));
        %let st = %scan(&statelist, &i);
        %let statename = &&state_&st;

        /* Capture ONLY the Estimates table for this run */
        ods select Estimates;
        ods output Estimates = YearSlopes_tmp;

        %if &st = 0 %then %do;
            /* Nationwide analysis (all states) */
            proc surveylogistic data = work.analysis_data;
                class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param = GLM;

                model currentsmoker(event = '1') =
                      year_centered
                      URRU
                      year_centered*URRU
                      _AGE_G SEXVAR _RACEGR3 _EDUCAG;

                weight  _LLCPWT;
                strata  _STSTR;
                cluster _PSU;

                /* Simple-slope odds ratios */
                estimate "Year slope URRU=0 (&statename)"  year_centered 1 / exp cl;
                estimate "Year slope URRU=1 (&statename)"  year_centered 1 year_centered*URRU 1 / exp cl;
            run;
        %end;
        %else %do;
            /* State-specific analysis */
            proc surveylogistic data = work.analysis_data;
                where _STATE = &st;

                class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param = GLM;

                model currentsmoker(event = '1') =
                      year_centered
                      URRU
                      year_centered*URRU
                      _AGE_G SEXVAR _RACEGR3 _EDUCAG;

                weight  _LLCPWT;
                strata  _STSTR;
                cluster _PSU;

                /* Simple-slope odds ratios */
                estimate "Year slope URRU=0 (&statename)"  year_centered 1 / exp cl;
                estimate "Year slope URRU=1 (&statename)"  year_centered 1 year_centered*URRU 1 / exp cl;
            run;
        %end;

        /* Tag rows with the state code and name, append to master set */
        data YearSlopes_tmp;
            set YearSlopes_tmp;
            State_Code = &st;
            State_Name = "&statename";
        run;

        proc append base = YearSlopes_All data = YearSlopes_tmp force;
        run;
    %end;
%mend SimpleSlopes;

%SimpleSlopes;

/* Review combined table */
proc print data = YearSlopes_All;
    var State_Code State_Name Label ExpEstimate LowerExp UpperExp ProbT;
    title "Simple Slopes: Year Effect by URRU Level (States with Significant Interactions)";
run;

/* Export to CSV */
proc export data = YearSlopes_All
    outfile = "output/tables/YearSlopes_v17_significant.csv"
    dbms = csv replace;
run;

/* Export to Excel */
ods excel file="output/reports/YearSlopes_v17_significant.xlsx";
proc print data=YearSlopes_All noobs;
    var State_Code State_Name Label ExpEstimate LowerExp UpperExp ProbT;
    title "Simple Slopes: Year Effect by URRU Level";
run;
ods excel close;

%put ========================================;
%put SIMPLE SLOPES ANALYSIS COMPLETE;
%put 16 analyses run (15 states + nationwide);
%put Output files created;
%put ========================================;
