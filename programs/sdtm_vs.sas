/*******************************************************************************
Program Name: sdtm_vs.sas
Description:  Mapping of raw EDC data to the SDTM VS (Vital Signs) domain.
              Demonstrates horizontal-to-vertical unpivoting and unit mapping.
*******************************************************************************/

%let project_path = /home/u64384931/Clinical-data-to-cdisc;

libname raw "&project_path./data/raw";
libname sdtm "&project_path./data/sdtm";


/* 1. IMPORT RAW VITALS */
proc import datafile="&project_path./data/raw/raw_vitals.csv"
    out=work.raw_vs
    dbms=csv
    replace;
    getnames=yes;
run;


/* 2. HORIZONTAL TO VERTICAL TRANSFORMATION (UNPIVOT) */
data work.vs_vertical;
    set work.raw_vs;
    
    /* Pre-define lengths to avoid truncation during the OUTPUT loops */
    length VSTESTCD $8 VSTEST $40 VSORRESU VSSTRESU $20 VSORRES $200;

    /* Core Identifiers */
    STUDYID = "CDISC-01";
    DOMAIN  = "VS";
    USUBJID = catx("-", STUDYID, PT_ID); /* Linking Raw PT_ID to CDISC USUBJID */

    /* --------------------------------------------------------
       ISO 8601 DATE CONVERSION
       -------------------------------------------------------- */
    if vtype(VS_DATE) = 'C' then _vs_num = input(strip(VS_DATE), anydtdte.);
    else _vs_num = VS_DATE;
    
    if not missing(_vs_num) then VSDTC = put(_vs_num, is8601da.);

    /* --------------------------------------------------------
       EXPLICIT OUTPUT STATEMENTS (CREATING MULTIPLE ROWS PER SUBJECT)
       -------------------------------------------------------- */
       
    /* 1. Systolic Blood Pressure */
    if not missing(SYS_BP) then do;
        VSTESTCD = "SYSBP";
        VSTEST   = "Systolic Blood Pressure";
        VSORRES  = strip(put(SYS_BP, best.)); /* Original Result as Character */
        VSSTRESN = SYS_BP;                    /* Standardized Result as Numeric */
        VSORRESU = "mmHg";
        VSSTRESU = "mmHg";
        output; /* Creates a row */
    end;

    /* 2. Diastolic Blood Pressure */
    if not missing(DIA_BP) then do;
        VSTESTCD = "DIABP";
        VSTEST   = "Diastolic Blood Pressure";
        VSORRES  = strip(put(DIA_BP, best.));
        VSSTRESN = DIA_BP;
        VSORRESU = "mmHg";
        VSSTRESU = "mmHg";
        output; /* Creates a row */
    end;

    /* 3. Heart Rate */
    if not missing(HR_BPM) then do;
        VSTESTCD = "HR";
        VSTEST   = "Heart Rate";
        VSORRES  = strip(put(HR_BPM, best.));
        VSSTRESN = HR_BPM;
        VSORRESU = "beats/min";
        VSSTRESU = "beats/min";
        output; /* Creates a row */
    end;

    /* 4. Weight */
    if not missing(WEIGHT_KG) then do;
        VSTESTCD = "WEIGHT";
        VSTEST   = "Weight";
        VSORRES  = strip(put(WEIGHT_KG, best.));
        VSSTRESN = WEIGHT_KG;
        VSORRESU = "kg";
        VSSTRESU = "kg";
        output; /* Creates a row */
    end;

    /* Keep only SDTM compliant variables */
    keep STUDYID DOMAIN USUBJID VISIT VSDTC VSTESTCD VSTEST VSORRES VSORRESU VSSTRESN VSSTRESU;
run;


/* 3. SORTING ACCORDING TO CDISC SDTMIG STANDARDS */
proc sort data=work.vs_vertical out=sdtm.vs;
    by USUBJID VSDTC VSTESTCD;
run;


/* 4. VISUAL AUDIT */
title "VS Domain Audit (Unpivoted Format)";
proc print data=sdtm.vs(obs=12);
    var USUBJID VISIT VSDTC VSTESTCD VSSTRESN VSSTRESU;
run;
title;