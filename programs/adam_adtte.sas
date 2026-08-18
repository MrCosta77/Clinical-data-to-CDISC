/*******************************************************************************
Program Name: adam_adtte.sas
Description:  Derivation of ADTTE (Time-to-Event Analysis Dataset).
              Calculates Time to First Adverse Event (Survival Analysis).
*******************************************************************************/

%include "/home/u64384931/Clinical-data-to-cdisc/programs/00_setup.sas";

/* 1. GET FIRST ADVERSE EVENT PER SUBJECT */
proc sort data=adam.adae out=work.adae_first;
    by USUBJID AESTDT; 
    where TRTEMFL = 'Y'; 
run;

data work.ae_target;
    set work.adae_first;
    by USUBJID;
    if first.USUBJID;
    keep USUBJID AESTDT;
    rename AESTDT = EVENTDT; 
run;


proc sort data=adam.adsl out=work.adsl_sorted;
    by USUBJID;
run;

/* NOVO: Extrair dinamicamente a data mais recente do estudo */
proc sql noprint;
    select max(ASTDT) format=date9. into :study_cutoff 
    from adam.advs;
quit;
%put INFO: Dynamic Study Cutoff Date is &study_cutoff;

data adam.adtte;
    retain STUDYID USUBJID PARAMCD PARAM;
    
    merge work.adsl_sorted(in=a) work.ae_target(in=b);
    by USUBJID;
    
    if a and SAFFL = 'Y'; 

    PARAMCD = "TTFAEV";
    PARAM   = "Time to First Adverse Event";

    /* --------------------------------------------------------
       3. DERIVE CENSORING (CNSR) AND TIME (AVAL)
       -------------------------------------------------------- */
    if not missing(EVENTDT) then do;
        /* O doente teve um evento */
        CNSR = 0; 
        AVAL = (EVENTDT - TRTSDT) + 1; /* Dias até ao evento */
    end;
    else do;
        CNSR = 1; 
        if not missing(TRTEDT) then AVAL = (TRTEDT - TRTSDT) + 1;
        /* Usa a variável dinâmica em vez da data esculpida na pedra */
        else AVAL = ("&study_cutoff"d - TRTSDT) + 1; 
    end;

    if AVAL < 0 then AVAL = 0;

    keep STUDYID USUBJID TRT01P TRT01A TRTSDT TRTEDT PARAMCD PARAM CNSR AVAL EVENTDT;
run;


/* 4. VISUAL AUDIT */
title "ADTTE Audit - Time to First Adverse Event";
proc print data=adam.adtte(obs=15);
    var USUBJID TRT01A PARAM CNSR AVAL EVENTDT TRTEDT;
run;
title;