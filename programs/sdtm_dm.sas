/*******************************************************************************
Program Name: sdtm_dm.sas
Description:  Mapping of raw EDC data to the SDTM DM (Demographics) domain.
              Includes data cleansing, controlled terminology alignment, 
              and ISO 8601 date conversion.
*******************************************************************************/

/* 1. ENVIRONMENT AND LIBRARY SETUP */
%let project_path = /home/u64384931/Clinical-data-to-cdisc;

libname raw "&project_path./data/raw";
libname sdtm "&project_path./data/sdtm";


/* 2. IMPORT RAW EDC DATA */
proc import datafile="&project_path./data/raw/raw_demog.csv"
    out=work.raw_dm
    dbms=csv
    replace;
    getnames=yes;
run;


/* 3. TRANSFORMATION AND SDTM MAPPING */
data sdtm.dm;
    set work.raw_dm;
    length ARM $20 ARMCD $8;
    
    /* Study Identifier Variables (Required) */
    STUDYID = "CDISC-01";
    DOMAIN  = "DM";
    
    /* USUBJID Creation (Unique Subject Identifier) */
    /* CDISC Rule: Concatenation of STUDYID and Subject ID */
    SUBJID  = SUBJ_ID;
    USUBJID = catx("-", STUDYID, SUBJID);
    
    /* --------------------------------------------------------
       CONTROLLED TERMINOLOGY CLEANING
       -------------------------------------------------------- */
    
    /* EDC has 'M', 'F', 'Male', 'Female'. CDISC strictly requires 'M' or 'F' */
    if upcase(char(GENDER, 1)) = 'M' then SEX = 'M';
    else if upcase(char(GENDER, 1)) = 'F' then SEX = 'F';
    else SEX = 'U'; /* Unknown */
    
    /* Race (Uppercase, per standard) */
    RACE = upcase(RACE_TXT);
    
    /* --------------------------------------------------------
       TRIAL DESIGN VARIABLES (ARM, ARMCD)
       -------------------------------------------------------- */
    /* Mapping the Planned Arm from the EDC system */
    if strip(RANDOMIZED_ARM) = 'Not Randomized' then do;
        ARM = 'SCREEN FAILURE';
        ARMCD = 'SCRNFAIL';
    end;
    else if strip(RANDOMIZED_ARM) = 'Placebo' then do;
        ARM = 'Placebo';
        ARMCD = 'PBO';
    end;
    else if strip(RANDOMIZED_ARM) = 'Active Drug 50mg' then do;
        ARM = 'Active Drug 50mg';
        ARMCD = 'ACT50';
    end;
/* --------------------------------------------------------
       ISO 8601 DATE CONVERSION (YYYY-MM-DD)
       (Dynamic type-checking to prevent proc import errors)
       -------------------------------------------------------- */
    
    /* Handle Birth Date (BRTH_DT) */
    if vtype(BRTH_DT) = 'C' then _brth_num = input(strip(BRTH_DT), anydtdte.);
    else _brth_num = BRTH_DT;
    
    if not missing(_brth_num) then BRTHDTC = put(_brth_num, is8601da.);
    
    /* Handle Informed Consent Date (ICF_DAT) */
    if vtype(ICF_DAT) = 'C' then _rfic_num = input(strip(ICF_DAT), anydtdte.);
    else _rfic_num = ICF_DAT;
    
    if not missing(_rfic_num) then RFICDTC = put(_rfic_num, is8601da.);
    
    /* Keep only variables that belong to the SDTM standard */
    keep STUDYID DOMAIN USUBJID SUBJID SEX RACE BRTHDTC RFICDTC ARM ARMCD;
run;


/* 4. VISUAL AUDIT (Quality Check) */
title "DM Domain Audit (First 10 Records)";
proc print data=sdtm.dm(obs=10);
    var STUDYID USUBJID SEX RACE BRTHDTC RFICDTC ARM ARMCD;
run;
title;