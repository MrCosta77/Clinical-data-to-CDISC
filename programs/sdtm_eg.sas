/*******************************************************************************
Program Name: sdtm_eg.sas
Description:  Transforms raw ECG data into CDISC SDTM EG domain.
*******************************************************************************/
%include "/home/u64384931/Clinical-data-to-cdisc/programs/00_setup.sas";

proc import datafile="&project_path./data/raw/raw_ecg.csv" 
    out=work.raw_eg dbms=csv replace; 
    getnames=yes; 
run;

data sdtm.eg;
    retain STUDYID DOMAIN USUBJID EGSEQ EGTESTCD EGTEST EGORRES EGORRESU EGDTC;
    length STUDYID $8 DOMAIN $2 USUBJID $200 EGTESTCD $8 EGTEST $40 EGORRES $20 EGORRESU $20 EGDTC $10;
    
    set work.raw_eg;
    
    STUDYID = "CDISC-001";
    DOMAIN = "EG";
    USUBJID = strip(SUBJECT);
    EGTEST = strip(TEST_NAME);
    
    /* Assign short codes based on the test name */
    if EGTEST = "Heart Rate" then EGTESTCD = "HR";
    else if EGTEST = "QT Duration" then EGTESTCD = "QT";
    else if EGTEST = "RR Duration" then EGTESTCD = "RR";
    else EGTESTCD = "UNKNOWN";
    
    EGORRES = strip(put(RESULT, best.));
    EGORRESU = strip(UNIT);
    EGDTC = strip(DATE);
run;

proc sort data=sdtm.eg; 
    by USUBJID EGDTC EGTESTCD; 
run;

data sdtm.eg; 
    set sdtm.eg; 
    by USUBJID; 
    if first.USUBJID then EGSEQ=1; 
    else EGSEQ+1; 
run;