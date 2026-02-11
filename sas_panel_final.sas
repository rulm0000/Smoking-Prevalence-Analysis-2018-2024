/******************************************************************************
* SAS PANEL PLOT - 15 ENTITIES - FINAL VERSION
* Predicted probabilities for Nationwide + 14 states
* Model 3b with URRU x year_centered interaction
******************************************************************************/

* Define paths using %nrstr() to handle apostrophe;
%let datafile = data/combinedbrfss_18_24v10.csv;
%let outdir = output;

ods listing gpath="&outdir";
ods graphics on / width=2400px height=1600px imagename="sas_panel_15entities" imagefmt=png;

* Import data;
proc import datafile="&datafile" out=brfss dbms=csv replace;
    getnames=yes;
run;

* Clean data;
data brfss;
    set brfss;
    if nmiss(_AGE_G, SEXVAR, _RACEGR3, URRU, currentsmoker, _EDUCAG, _STATE, _LLCPWT, _PSU, _STSTR, year_centered) = 0;
run;

* Get weighted means;
proc means data=brfss noprint;
    var _AGE_G SEXVAR _RACEGR3 _EDUCAG;
    weight _LLCPWT;
    output out=means mean=;
run;

* Create scoring dataset;
data score;
    set means(keep=_AGE_G SEXVAR _RACEGR3 _EDUCAG);
    _AGE_G = round(_AGE_G);
    SEXVAR = round(SEXVAR);
    _RACEGR3 = round(_RACEGR3);
    _EDUCAG = round(_EDUCAG);
    do URRU = 0, 1;
        do year_centered = -2 to 4;
            output;
        end;
    end;
run;

/*** Process all 15 entities ***/

* Nationwide - create initial preds dataset;
data temp; set brfss; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink;
run;
data s; set s; rename Predicted=P_1 Lower=Lower_1 Upper=Upper_1; run;
data preds; length entity $30; set s; entity= "Nationwide" ; row=1; run;

* Arizona;
data temp; set brfss; where _STATE=4; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Arizona" ; row=2; run;
proc append base=preds data=s; run;

* Arkansas;
data temp; set brfss; where _STATE=5; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Arkansas" ; row=3; run;
proc append base=preds data=s; run;

* Colorado;
data temp; set brfss; where _STATE=8; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Colorado" ; row=4; run;
proc append base=preds data=s; run;

* Georgia;
data temp; set brfss; where _STATE=13; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Georgia" ; row=5; run;
proc append base=preds data=s; run;

* Iowa;
data temp; set brfss; where _STATE=19; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Iowa" ; row=6; run;
proc append base=preds data=s; run;

* Kansas;
data temp; set brfss; where _STATE=20; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Kansas" ; row=7; run;
proc append base=preds data=s; run;

* Maine;
data temp; set brfss; where _STATE=23; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Maine" ; row=8; run;
proc append base=preds data=s; run;

* Mississippi;
data temp; set brfss; where _STATE=28; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Mississippi" ; row=9; run;
proc append base=preds data=s; run;

* Missouri;
data temp; set brfss; where _STATE=29; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Missouri" ; row=10; run;
proc append base=preds data=s; run;

* Montana;
data temp; set brfss; where _STATE=30; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Montana" ; row=11; run;
proc append base=preds data=s; run;

* Nebraska;
data temp; set brfss; where _STATE=31; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Nebraska" ; row=12; run;
proc append base=preds data=s; run;

* South Carolina;
data temp; set brfss; where _STATE=45; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "South Carolina" ; row=13; run;
proc append base=preds data=s; run;

* Washington;
data temp; set brfss; where _STATE=53; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Washington" ; row=14; run;
proc append base=preds data=s; run;

* Wisconsin;
data temp; set brfss; where _STATE=55; run;
proc logistic data=temp noprint;
    class URRU (ref='0') _AGE_G SEXVAR _RACEGR3 _EDUCAG / param=glm;
    model currentsmoker (event='1') = URRU year_centered _AGE_G SEXVAR _RACEGR3 _EDUCAG URRU*year_centered;
    weight _LLCPWT;
    store model_store;
run;
proc plm restore=model_store noinfo;
    score data=score out=s / ilink alpha=0.05;
run;
data s; set s; rename Predicted=P_1 LowerCLMean=Lower_1 UpperCLMean=Upper_1; entity= "Wisconsin" ; row=15; run;
proc append base=preds data=s; run;

* Calculate unadjusted weighted prevalence;
* For state-level prevalence;
proc means data=brfss noprint;
    class _STATE year_centered URRU;
    where _STATE in (4,5,8,13,19,20,23,28,29,30,31,45,53,55);
    var currentsmoker;
    weight _LLCPWT;
    types _STATE*year_centered*URRU;
    output out=prevalence mean=prev;
run;

* Map state codes to entity names;
data prevalence;
    set prevalence;
    year = 2020 + year_centered;
    if _STATE = . then entity = "Nationwide";
    else if _STATE = 4 then entity = "Arizona";
    else if _STATE = 5 then entity = "Arkansas";
    else if _STATE = 8 then entity = "Colorado";
    else if _STATE = 13 then entity = "Georgia";
    else if _STATE = 19 then entity = "Iowa";
    else if _STATE = 20 then entity = "Kansas";
    else if _STATE = 23 then entity = "Maine";
    else if _STATE = 28 then entity = "Mississippi";
    else if _STATE = 29 then entity = "Missouri";
    else if _STATE = 30 then entity = "Montana";
    else if _STATE = 31 then entity = "Nebraska";
    else if _STATE = 45 then entity = "South Carolina";
    else if _STATE = 53 then entity = "Washington";
    else if _STATE = 55 then entity = "Wisconsin";
    else delete;
    if URRU = 0 then location =  "Urban" ;
    else location =  "Rural" ;
    keep entity year location prev;
run;

* Get nationwide prevalence;
proc means data=brfss noprint;
    class year_centered URRU;
    var currentsmoker;
    weight _LLCPWT;
    types year_centered*URRU;
    output out=prev_nation mean=prev;
run;

data prev_nation;
    set prev_nation;
    year = 2020 + year_centered;
    entity = "Nationwide";
    if URRU = 0 then location =  "Urban" ;
    else location =  "Rural" ;
    keep entity year location prev;
run;

* Combine prevalence data;
data prevalence;
    set prev_nation prevalence;
run;

* Prepare predicted probabilities for plotting;
data plot_pred;
    set preds;
    year = 2020 + year_centered;
    pred = P_1;
    if URRU = 0 then location =  "Urban" ;
    else location =  "Rural" ;
    keep entity row year location pred;
run;

* Merge predictions with prevalence;
proc sql;
    create table plot as
    select a.*, b.prev
    from plot_pred as a
    left join prevalence as b
    on a.entity = b.entity and a.year = b.year and a.location = b.location;
quit;

* Create panel plot;
proc sgpanel data=plot;
    panelby entity / columns=3 rows=5 novarname spacing=5 headerattrs=(size=12pt weight=bold) sort=data;
    scatter x=year y=prev / group=location markerattrs=(size=8 symbol=circlefilled);
    series x=year y=pred / group=location lineattrs=(thickness=2) name='series';
    rowaxis min=0 max=0.35 values=(0 to 0.35 by 0.05)
            label= "Predicted Probability"  labelattrs=(size=14pt weight=bold);
    colaxis min=2018 max=2024 values=(2018 to 2024)
            label= "Year"  labelattrs=(size=14pt weight=bold);
    styleattrs datacontrastcolors=(navy red) datalinepatterns=(solid dot);
    keylegend 'series' / position=bottom valueattrs=(size=12pt);
run;

* Export;
proc export data=plot outfile="&outdir/sas_predictions_15entities.csv" dbms=csv replace;
run;

ods graphics off;

%put =================================================================;
%put ANALYSIS COMPLETE;
%put =================================================================;
