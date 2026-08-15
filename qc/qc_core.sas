/*******************************************************************************
Program Name: qc_core.sas
Description:  Automated Quality Control (QC) checks for the clinical pipeline.
              Outputs a consolidated QC report of data anomalies.
*******************************************************************************/

/* =====================================================================
   Ensure 00_setup.sas has been executed before running this script
   so that all libnames (adam, sdtm) are active.
   ===================================================================== */

/* -------------------------------------------------------------------
   CHECK 1: ADSL - Check for duplicate USUBJID
   ------------------------------------------------------------------- */
proc sql noprint;
    select count(*) into :fails_dm01
    from (
        select USUBJID, count(*) as cnt 
        from adam.adsl 
        group by USUBJID 
        having count(*) > 1
    );
quit;

data work.chk_dm01;
    length CHECK_ID $10 DOMAIN $10 RULE $50 N_FAIL 8 STATUS $10;
    CHECK_ID = "ADSL-001"; DOMAIN = "ADSL"; RULE = "USUBJID must be perfectly unique";
    N_FAIL = &fails_dm01;
    if N_FAIL = 0 then STATUS = "PASS"; else STATUS = "FAIL";
run;


/* -------------------------------------------------------------------
   CHECK 2: ADAE - End Date cannot be before Start Date
   ------------------------------------------------------------------- */
proc sql noprint;
    select count(*) into :fails_ae01
    from adam.adae
    where not missing(AEENDT) and not missing(AESTDT) and AEENDT < AESTDT;
quit;

data work.chk_ae01;
    length CHECK_ID $10 DOMAIN $10 RULE $50 N_FAIL 8 STATUS $10;
    CHECK_ID = "ADAE-001"; DOMAIN = "ADAE"; RULE = "AEENDT must be >= AESTDT";
    N_FAIL = &fails_ae01;
    if N_FAIL = 0 then STATUS = "PASS"; else STATUS = "FAIL";
run;


/* -------------------------------------------------------------------
   CHECK 3: ADVS - Baseline (ABLFL='Y') must not duplicate per parameter
   ------------------------------------------------------------------- */
proc sql noprint;
    select count(*) into :fails_vs01
    from (
        select USUBJID, PARAMCD, count(*) as cnt 
        from adam.advs 
        where ABLFL = 'Y' 
        group by USUBJID, PARAMCD 
        having count(*) > 1
    );
quit;

data work.chk_vs01;
    length CHECK_ID $10 DOMAIN $10 RULE $50 N_FAIL 8 STATUS $10;
    CHECK_ID = "ADVS-001"; DOMAIN = "ADVS"; RULE = "Max 1 Baseline (ABLFL='Y') per Param";
    N_FAIL = &fails_vs01;
    if N_FAIL = 0 then STATUS = "PASS"; else STATUS = "FAIL";
run;


/* -------------------------------------------------------------------
   CONSOLIDATE AND PRINT REPORT
   ------------------------------------------------------------------- */
data work.qc_results;
    set work.chk_dm01 work.chk_ae01 work.chk_vs01;
run;

title "Automated Quality Control (QC) Validation Report";
proc print data=work.qc_results noobs;
run;
title;