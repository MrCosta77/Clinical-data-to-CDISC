/*******************************************************************************
Program Name: generate_define.sas
Description:  Dynamically extracts metadata from SDTM and ADaM libraries and 
              generates a structural CDISC Define-XML v2.0 document.
*******************************************************************************/

%include "/home/u64384931/Clinical-data-to-cdisc/programs/00_setup.sas";

/* 1. Extract structural metadata from SDTM and ADaM libraries */
proc sql noprint;
    create table meta_data as
    select upcase(libname) as libname, 
           upcase(memname) as dataset, 
           upcase(name) as variable, 
           type, length, label
    from dictionary.columns
    where libname in ('SDTM', 'ADAM')
    order by libname, dataset, varnum;
quit;

/* 2. Initialize XML File and Write Header */
data _null_;
    file "&project_path./tlfs/define.xml" encoding="utf-8";
    put '<?xml version="1.0" encoding="UTF-8"?>';
    put '<ODM xmlns="http://www.cdisc.org/ns/odm/v1.3" xmlns:def="http://www.cdisc.org/ns/def/v2.0" FileType="Snapshot">';
    put '  <Study OID="STU.001">';
    put '    <GlobalVariables>';
    put '      <StudyName>Portfolio Clinical Trial</StudyName>';
    put '      <StudyDescription>End-to-End CDISC Pipeline Automation</StudyDescription>';
    put '      <ProtocolName>CDISC-001</ProtocolName>';
    put '    </GlobalVariables>';
    put '    <MetaDataVersion OID="MDV.001" Name="Study Metadata" def:DefineVersion="2.0.0">';
run;

/* 3. Write ItemGroupDefs (Datasets mapping) */
data _null_;
    set meta_data;
    by libname dataset;
    file "&project_path./tlfs/define.xml" mod encoding="utf-8";
    
    length ds_name $32 var_name $32 lib_name $10 line $1024;
    ds_name = strip(dataset);
    var_name = strip(variable);
    lib_name = strip(libname);
    
    if first.dataset then do;
        line = cats('      <ItemGroupDef OID="IG.', ds_name,
                    '" Name="', ds_name,
                    '" Repeating="Yes" IsReferenceData="No">');
        put line;
        line = cats('        <Description><TranslatedText>', ds_name,
                    ' Dataset (', lib_name,
                    ')</TranslatedText></Description>');
        put line;
    end;

    line = cats('        <ItemRef ItemOID="IT.', ds_name, '.', var_name,
                '" Mandatory="No"/>');
    put line;
    
    if last.dataset then do;
        put '      </ItemGroupDef>';
    end;
run;

/* 4. Write ItemDefs (Variables mapping) */
proc sort data=meta_data nodupkey out=unique_vars;
    by dataset variable;
run;

data _null_;
    set unique_vars;
    file "&project_path./tlfs/define.xml" mod encoding="utf-8";
    
    length ds_name $32 var_name $32 var_lbl $256 dt_type $10 len_str $5
           line $1024;
    ds_name = strip(dataset);
    var_name = strip(variable);
    var_lbl = strip(label);
    if missing(var_lbl) then var_lbl = var_name; /* Fallback caso não tenha label */
    
    if type = 'char' then dt_type = 'text';
    else dt_type = 'integer';
    
    len_str = strip(put(length, best.));
    
    line = cats('      <ItemDef OID="IT.', ds_name, '.', var_name,
                '" Name="', var_name, '" DataType="', dt_type,
                '" Length="', len_str, '">');
    put line;
    line = cats('        <Description><TranslatedText>', var_lbl,
                '</TranslatedText></Description>');
    put line;
    put '      </ItemDef>';
run;

/* 5. Close XML Tags */
data _null_;
    file "&project_path./tlfs/define.xml" mod encoding="utf-8";
    put '    </MetaDataVersion>';
    put '  </Study>';
    put '</ODM>';
run;
