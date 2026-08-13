/*******************************************************************************
Program Name: adam_advs.sas
Description:  Derivation of ADVS (Vital Signs Analysis Dataset).
              Merges ADSL with SDTM VS to derive Baseline Flags (ABLFL),
              Baseline Values (BASE), and Change from Baseline (CHG).
*******************************************************************************/

%let project_path = /home/u64384931/Clinical-data-to-cdisc;

libname sdtm "&project_path./data/sdtm";
libname adam "&project_path./data/adam";

/* 1. MERGE ADSL AND VS */
proc sort data=adam.adsl out=work.adsl_sorted;
    by USUBJID;
run;

proc sort data=sdtm.vs out=work.vs_sorted;
    by USUBJID VSDTC VSTESTCD;
run;

data work.advs_draft;
    merge work.adsl_sorted(in=a) work.vs_sorted(in=b);
    by USUBJID;
    if b; /* Keep only records that have vital signs */

    /* --------------------------------------------------------
       CORE ANALYSIS VARIABLES
       -------------------------------------------------------- */
    PARAMCD = VSTESTCD;
    PARAM   = VSTEST;
    AVAL    = VSSTRESN;
    AVISIT  = VISIT;

    /* Convert ISO Date to Numeric Analysis Date */
    if length(VSDTC) >= 10 then ASTDT = input(substr(VSDTC, 1, 10), yymmdd10.);
    format ASTDT date9.;

    /* Analysis Relative Day (ASTDY) */
    if not missing(ASTDT) and not missing(TRTSDT) then do;
        if ASTDT >= TRTSDT then ASTDY = (ASTDT - TRTSDT) + 1;
        else ASTDY = ASTDT - TRTSDT;
    end;

    keep STUDYID USUBJID TRT01A TRTSDT TRTEDT PARAMCD PARAM AVAL AVISIT ASTDT ASTDY;
run;


/* 2. IDENTIFY BASELINE RECORD */
/* Baseline is typically the last non-missing assessment on or before the first dose */
proc sort data=work.advs_draft out=work.advs_base_candidates;
    by USUBJID PARAMCD ASTDT;
    where ASTDT <= TRTSDT and not missing(AVAL);
run;

data work.base_flags;
    set work.advs_base_candidates;
    by USUBJID PARAMCD;
    
    /* The last record before or on treatment start is the baseline */
    if last.PARAMCD then do;
        ABLFL = 'Y';
        BASE = AVAL;
    end;
    
    if ABLFL = 'Y';
    keep USUBJID PARAMCD BASE ABLFL;
run;


/* 3. MERGE BASELINE BACK TO ALL RECORDS AND CALCULATE CHANGE (CHG) */
proc sort data=work.advs_draft;
    by USUBJID PARAMCD;
run;

data adam.advs;
    merge work.advs_draft(in=a) work.base_flags(in=b);
    by USUBJID PARAMCD;
    if a;

    /* Calculate Change from Baseline */
    if not missing(AVAL) and not missing(BASE) then do;
        CHG = AVAL - BASE;
    end;
run;

/* Re-sort for final presentation */
proc sort data=adam.advs;
    by USUBJID PARAMCD ASTDT;
run;


/* 4. VISUAL AUDIT */
title "ADVS Audit - Vital Signs with Baseline and Change";
proc print data=adam.advs(obs=12);
    var USUBJID AVISIT PARAMCD AVAL BASE CHG ABLFL ASTDY;
run;
title;