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
       ISO 8601 DATE CONVERSION (YYYY-MM-DD)
       -------------------------------------------------------- */
    
    /* BRTH_DT comes from Python as DD/MM/YYYY */
    _brth_num = input(BRTH_DT, ddmmyy10.);
    BRTHDTC   = put(_brth_num, yymmddd10.);
    
    /* ICF_DAT comes from Python as YYYY-MM-DD */
    _rfic_num = input(ICF_DAT, yymmdd10.);
    RFICDTC   = put(_rfic_num, yymmddd10.);
    
    /* Keep only variables that belong to the SDTM standard */
    keep STUDYID DOMAIN USUBJID SUBJID SEX RACE BRTHDTC RFICDTC;
run;


/* 4. VISUAL AUDIT (Quality Check) */
title "DM Domain Audit (First 10 Records)";
proc print data=sdtm.dm(obs=10);
    var STUDYID USUBJID SEX RACE BRTHDTC RFICDTC;
run;
title;