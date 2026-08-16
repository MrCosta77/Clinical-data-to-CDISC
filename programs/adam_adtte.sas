/*******************************************************************************
Program Name: adam_adtte.sas
Description:  Derivation of ADTTE (Time-to-Event Analysis Dataset).
              Calculates Time to First Adverse Event (Survival Analysis).
*******************************************************************************/

/* 1. GET FIRST ADVERSE EVENT PER SUBJECT */
proc sort data=adam.adae out=work.adae_first;
    by USUBJID ASTDT;
    where TRTEMFL = 'Y'; /* Analisar apenas eventos Treatment-Emergent */
run;

data work.ae_target;
    set work.adae_first;
    by USUBJID;
    if first.USUBJID; /* Guardar estritamente o primeiro evento adverso */
    keep USUBJID ASTDT;
    rename ASTDT = EVENTDT;
run;


/* 2. MERGE WITH POPULATION (ADSL) */
proc sort data=adam.adsl out=work.adsl_sorted;
    by USUBJID;
run;

data adam.adtte;
    retain STUDYID USUBJID PARAMCD PARAM;
    
    merge work.adsl_sorted(in=a) work.ae_target(in=b);
    by USUBJID;
    
    /* A análise de segurança/sobrevivência foca-se na Safety Population */
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
        /* O doente concluiu o estudo sem eventos (Censurado) */
        CNSR = 1; 
        if not missing(TRTEDT) then AVAL = (TRTEDT - TRTSDT) + 1;
        else AVAL = .; /* Proteção para missing data */
    end;

    /* Salvaguarda analítica: AVAL não pode ser negativo */
    if AVAL < 0 then AVAL = 0;

    keep STUDYID USUBJID TRT01P TRT01A TRTSDT TRTEDT PARAMCD PARAM CNSR AVAL EVENTDT;
run;


/* 4. VISUAL AUDIT */
title "ADTTE Audit - Time to First Adverse Event";
proc print data=adam.adtte(obs=15);
    var USUBJID TRT01A PARAM CNSR AVAL EVENTDT TRTEDT;
run;
title;