/* Import the data */
proc import datafile="C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\data\combinedbrfss_18_24v10.csv"
    out=work.CombinedBRFSS_18_24v10
    dbms=csv
    replace;
    getnames=yes;
run;

/* Model 1: Basic model with urban-rural and year for current smoking */
proc surveylogistic data=CombinedBRFSS_18_24v10;
    class URRU (ref='0') / param=GLM;
    model currentsmoker (event='1') = URRU year_centered;
    weight _llcpwt;
    strata _ststr;
    cluster _psu;
run;

/* Model 1: Basic model with urban-rural and year for former smoking */
proc surveylogistic data=CombinedBRFSS_18_24v10;
    class URRU (ref='0') / param=GLM;
    model Quit (event='1') = URRU year_centered;
    weight _llcpwt;
    strata _ststr;
    cluster _psu;
run;

/* Model 2: Adds demographics for current smoking */
proc surveylogistic data=CombinedBRFSS_18_24v10;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 / param=GLM;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3;
    weight _llcpwt;
    strata _ststr;
    cluster _psu;
run;

/* Model 2: Adds demographics for former smoking */
proc surveylogistic data=CombinedBRFSS_18_24v10;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 / param=GLM;
    model Quit (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3;
    weight _llcpwt;
    strata _ststr;
    cluster _psu;
run;

/* Model 3: Adds education variable for current smoking */
proc surveylogistic data=CombinedBRFSS_18_24v10;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=GLM;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG;
    weight _llcpwt;
    strata _ststr;
    cluster _psu;
run;

/* Model 3: Adds education variable for former smoking */
proc surveylogistic data=CombinedBRFSS_18_24v10;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=GLM;
    model Quit (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG;
    weight _llcpwt;
    strata _ststr;
    cluster _psu;
run;
