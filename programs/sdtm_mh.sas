/*******************************************************************************
Program Name: sdtm_mh.sas
Description:  Transforms raw Medical History data into CDISC SDTM MH domain.
*******************************************************************************/
%include "/home/u64384931/Clinical-data-to-cdisc/programs/00_setup.sas";

proc import datafile="&project_path./data/raw/raw_mh.csv" 
    out=work.raw_mh dbms=csv replace; 
    getnames=yes; 
run;

data sdtm.mh;
    retain STUDYID DOMAIN USUBJID MHSEQ MHTERM MHSTDTC;
    length STUDYID $8 DOMAIN $2 USUBJID $200 MHTERM $60 MHSTDTC $10;
    
    set work.raw_mh;
    
    STUDYID = "CDISC-01";
    DOMAIN = "MH";
    USUBJID = catx('-', STUDYID, strip(SUBJECT)); 
    MHTERM = strip(CONDITION);
    MHSTDTC = strip(DIAGNOSIS_DATE);
run;

proc sort data=sdtm.mh; 
    by USUBJID MHSTDTC; 
run;

data sdtm.mh; 
    set sdtm.mh; 
    by USUBJID; 
    if first.USUBJID then MHSEQ=1; 
    else MHSEQ+1; 
run;