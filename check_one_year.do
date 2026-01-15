local yr "`1'"
local vars "_RFSMOK3 SMOKE100 SMOKDAY2 _SMOKER3 _URBSTAT _URBNRRL IYEAR _AGE_G SEX1 SEXVAR _SEX _RACE _RACEGR3 EDUCA _EDUCAG MARITAL EMPLOY1 INCOME2 _INCOMG INCOME3 _INCOMG1 NUMADULT HHADULT CHILDREN _CHLDCNT MENTHLTH _MENT14D DECIDE ADDEPEV2 ADDEPEV3 CHECKUP1 _STATE _LLCPWT _STSTR _PSU"

capture import sasxport5 "C:\Users\culm\OneDrive - University of North Carolina at Chapel Hill\OUHSC Backup 6.26.23\Projects\Master's Project\Results\Updated Analysis\data\LLCP`yr'.XPT", clear
if _rc != 0 {
    di "Error importing LLCP`yr'.XPT"
    exit
}

di "Checking variables for `yr':"
foreach v in `vars' {
    capture confirm variable `v'
    if _rc == 0 {
        di "  `v': FOUND"
    }
    else {
        di "  `v': MISSING"
    }
}
