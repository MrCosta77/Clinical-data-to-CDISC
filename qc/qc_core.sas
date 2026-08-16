/*******************************************************************************
Program Name: qc_core.sas
Description:  Automated Quality Control (QC) Validation Framework.
              Runs cross-domain referential integrity checks and logical rules.
              Triggers ABORT CANCEL if critical errors are found.
              Generates a permanent audit dataset in the ADAM library.
*******************************************************************************/

%include "/home/u64384931/Clinical-data-to-cdisc/programs/00_setup.sas";

/* -------------------------------------------------------------------
   1. DEFINE VALIDATION RULES
   ------------------------------------------------------------------- */

/* RULE 1: ADSL - USUBJID must be perfectly unique */
proc sql noprint;
    create table chk_adsl01 as
    select 'ADSL-001' as CHECK_ID, 'ADSL' as DOMAIN, 'USUBJID must be perfectly unique' as RULE,
           count(*) as N_FAIL
    from (select USUBJID from adam.adsl group by USUBJID having count(*) > 1);
quit;

/* RULE 2: ADAE - Adverse Event End Date must be >= Start Date */
proc sql noprint;
    create table chk_adae01 as
    select 'ADAE-001' as CHECK_ID, 'ADAE' as DOMAIN, 'AEENDT must be >= AESTDT' as RULE,
           count(*) as N_FAIL
    from adam.adae
    where AEENDT < AESTDT and not missing(AEENDT) and not missing(AESTDT);
quit;

/* RULE 3: ADVS - Maximum 1 Baseline (ABLFL='Y') per Parameter per Subject */
proc sql noprint;
    create table chk_advs01 as
    select 'ADVS-001' as CHECK_ID, 'ADVS' as DOMAIN, 'Max 1 Baseline (ABLFL=Y) per Param' as RULE,
           count(*) as N_FAIL
    from (select USUBJID, PARAMCD from adam.advs where ABLFL = 'Y' group by USUBJID, PARAMCD having count(*) > 1);
quit;

/* RULE 4: ADLB - Maximum 1 Baseline (ABLFL='Y') per Parameter per Subject */
proc sql noprint;
    create table chk_adlb01 as
    select 'ADLB-001' as CHECK_ID, 'ADLB' as DOMAIN, 'Max 1 Baseline (ABLFL=Y) per Param' as RULE,
           count(*) as N_FAIL
    from (select USUBJID, PARAMCD from adam.adlb where ABLFL = 'Y' group by USUBJID, PARAMCD having count(*) > 1);
quit;

/* RULE 5: SDTM DM - No duplicate records */
proc sql noprint;
    create table chk_dm01 as
    select 'SDTM-001' as CHECK_ID, 'DM' as DOMAIN, 'USUBJID must be perfectly unique' as RULE,
           count(*) as N_FAIL
    from (select USUBJID from sdtm.dm group by USUBJID having count(*) > 1);
quit;

/* RULE 6: SDTM AE - Referential Integrity (Subject must exist in DM) */
proc sql noprint;
    create table chk_ae01 as
    select 'SDTM-002' as CHECK_ID, 'AE' as DOMAIN, 'Every AE.USUBJID exists in DM' as RULE,
           count(*) as N_FAIL
    from sdtm.ae a left join sdtm.dm d on a.USUBJID = d.USUBJID
    where d.USUBJID is null;
quit;

/* RULE 7: SDTM EX - Referential Integrity */
proc sql noprint;
    create table chk_ex01 as
    select 'SDTM-003' as CHECK_ID, 'EX' as DOMAIN, 'Every EX.USUBJID exists in DM' as RULE,
           count(*) as N_FAIL
    from sdtm.ex a left join sdtm.dm d on a.USUBJID = d.USUBJID
    where d.USUBJID is null;
quit;

/* RULE 8: SDTM LB - Referential Integrity */
proc sql noprint;
    create table chk_lb01 as
    select 'SDTM-004' as CHECK_ID, 'LB' as DOMAIN, 'Every LB.USUBJID exists in DM' as RULE,
           count(*) as N_FAIL
    from sdtm.lb a left join sdtm.dm d on a.USUBJID = d.USUBJID
    where d.USUBJID is null;
quit;

/* RULE 9: SDTM VS - Referential Integrity */
proc sql noprint;
    create table chk_vs01 as
    select 'SDTM-005' as CHECK_ID, 'VS' as DOMAIN, 'Every VS.USUBJID exists in DM' as RULE,
           count(*) as N_FAIL
    from sdtm.vs a left join sdtm.dm d on a.USUBJID = d.USUBJID
    where d.USUBJID is null;
quit;

/* RULE 10: ADSL - Safety Population (SAFFL='Y') requires Exposure in EX */
proc sql noprint;
    create table chk_adsl02 as
    select 'ADSL-002' as CHECK_ID, 'ADSL' as DOMAIN, 'SAFFL=Y requires exposure in EX' as RULE,
           count(*) as N_FAIL
    from adam.adsl a left join sdtm.ex e on a.USUBJID = e.USUBJID
    where a.SAFFL = 'Y' and e.USUBJID is null;
quit;

/* RULE 11: ADTTE - Survival time (AVAL) cannot be negative */
proc sql noprint;
    create table chk_adtte01 as
    select 'ADTE-001' as CHECK_ID, 'ADTTE' as DOMAIN, 'Survival time (AVAL) >= 0' as RULE,
           count(*) as N_FAIL
    from adam.adtte
    where AVAL < 0 and not missing(AVAL); /* CORREÇÃO: Ignorar explicitamente missing values SAS (.) */
quit;


/* -------------------------------------------------------------------
   2. CONSOLIDATE RESULTS (Generate Permanent Data)
   ------------------------------------------------------------------- */
data adam.qc_report;
    /* CORREÇÃO: Definir limites de texto ANTES do set previne os "Warnings" de truncation */
    length CHECK_ID $10 DOMAIN $10 RULE $50 STATUS $10;
    
    set chk_adsl01 chk_adae01 chk_advs01 chk_adlb01 chk_dm01 
        chk_ae01 chk_ex01 chk_lb01 chk_vs01 chk_adsl02 chk_adtte01;
        
    if N_FAIL = 0 then STATUS = "PASS";
    else STATUS = "FAIL";
run;


/* -------------------------------------------------------------------
   3. PRINT REPORT
   ------------------------------------------------------------------- */
title "Automated Quality Control (QC) Validation Report";
proc print data=adam.qc_report noobs;
    var CHECK_ID DOMAIN RULE N_FAIL STATUS;
run;
title;


/* -------------------------------------------------------------------
   4. SYSTEM ABORT LOGIC (The Professional Pipeline Stopper)
   ------------------------------------------------------------------- */
proc sql noprint;
    select count(*) into :n_failed
    from adam.qc_report
    where STATUS = "FAIL";
quit;

%macro abort_if_fail;
    %if &n_failed > 0 %then %do;
        %put ERROR: --------------------------------------------------;
        %put ERROR: QC PIPELINE FAILED. CRITICAL DATA ERRORS DETECTED.;
        %put ERROR: &n_failed VALIDATION RULES FAILED.;
        %put ERROR: EXECUTION ABORTED.;
        %put ERROR: --------------------------------------------------;
        %abort cancel;
    %end;
    %else %do;
        %put NOTE: ---------------------------------------------------;
        %put NOTE: QC VALIDATION COMPLETE. ALL 11 CHECKS PASSED SUCCESSFULLY.;
        %put NOTE: ---------------------------------------------------;
    %end;
%mend;

%abort_if_fail;