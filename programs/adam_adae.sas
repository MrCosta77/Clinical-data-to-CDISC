/*******************************************************************************
Program Name: adam_adae.sas
Description:  Derivation of ADAE (Adverse Events Analysis Dataset).
              Merges ADSL with SDTM AE to calculate numeric event dates, 
              study days (ASTDY), and Treatment-Emergent Flags (TRTEMFL).
*******************************************************************************/

%let project_path = /home/u64384931/Clinical-data-to-cdisc;

libname sdtm "&project_path./data/sdtm";
libname adam "&project_path./data/adam";


/* 1. SORT INPUT DATASETS BY UNIQUE SUBJECT ID */
proc sort data=adam.adsl out=work.adsl_sorted;
    by USUBJID;
run;

proc sort data=sdtm.ae out=work.ae_sorted;
    by USUBJID AESEQ;
run;


/* 2. MERGE ADSL AND AE TO CREATE ADAE */
data work.adae_draft;
    /* ADSL is the master patient list, AE contains multiple rows per patient */
    merge work.adsl_sorted(in=a) work.ae_sorted(in=b);
    by USUBJID;
    
    /* Keep only subjects who actually experienced an Adverse Event */
    if b; 

    /* --------------------------------------------------------
       NUMERIC DATE DERIVATIONS
       -------------------------------------------------------- */
    /* Convert ISO 8601 character dates to SAS numeric dates */
    if length(AESTDTC) >= 10 then AESTDT = input(substr(AESTDTC, 1, 10), yymmdd10.);
    if length(AEENDTC) >= 10 then AEENDT = input(substr(AEENDTC, 1, 10), yymmdd10.);
    
    format AESTDT AEENDT date9.;

    /* --------------------------------------------------------
       ANALYSIS RELATIVE DAYS (ASTDY)
       -------------------------------------------------------- */
    /* How many days after starting the drug did the event happen? 
       Rule: If event is on or after treatment start, Day 1 is TRTSDT. */
    if not missing(AESTDT) and not missing(TRTSDT) then do;
        if AESTDT >= TRTSDT then ASTDY = (AESTDT - TRTSDT) + 1;
        else ASTDY = AESTDT - TRTSDT;
    end;

    /* --------------------------------------------------------
       TREATMENT-EMERGENT FLAG (TRTEMFL)
       -------------------------------------------------------- */
    /* An event is Treatment-Emergent if it starts on or after the first dose 
       and the patient actually took the drug (SAFFL = 'Y') */
    if SAFFL = 'Y' and not missing(AESTDT) and not missing(TRTSDT) then do;
        if AESTDT >= TRTSDT then TRTEMFL = "Y";
        else TRTEMFL = "";
    end;
    else TRTEMFL = "";

    /* Keep the essential clinical and analysis variables */
    keep STUDYID USUBJID SUBJID TRT01A TRTSDT TRTEDT AGE SEX 
         AESEQ AETERM AEDECOD AESEV AEREL AEOUT 
         AESTDT AEENDT ASTDY TRTEMFL;
run;


/* 3. FINALIZE AND SAVE TO ADAM LIBRARY */
proc sort data=work.adae_draft out=adam.adae;
    by USUBJID AESTDT AESEQ;
run;


/* 4. VISUAL AUDIT */
title "ADAE Audit - Adverse Events with Treatment-Emergent Flags";
proc print data=adam.adae(obs=15);
    var USUBJID TRT01A AETERM AESEV AESTDT TRTSDT ASTDY TRTEMFL;
run;
title;