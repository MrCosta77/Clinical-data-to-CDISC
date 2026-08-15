/*******************************************************************************
Program Name: tlf_table1.sas
Description:  Generates Table 1: Demographics and Baseline Characteristics.
              Uses ODS RTF to export a professional Word document.
*******************************************************************************/

/* Abrir a porta RTF com o estilo 'Journal' sem fechar a do SAS Studio */
ods rtf file="&project_path./tlf_table1.rtf" style=Journal;

title1 "Table 1: Demographics and Baseline Characteristics";
title2 "Population: Intent-to-Treat (ITT)";

proc tabulate data=adam.adsl missing;
    /* Filter only randomized subjects */
    where ITTFL = 'Y'; 
    
    class TRT01P SEX RACE; 
    var AGE; 
    
    table 
        /* --- ROWS (Com formatação limpa e percentagens) --- */
        ALL="Total Subjects" * N=""
        SEX="Sex" * (N="n" * f=5.0 ColPctN="%" * f=5.1)
        RACE="Race" * (N="n" * f=5.0 ColPctN="%" * f=5.1)
        AGE="Age (years)" * (N="n" * f=5.0 Mean="Mean" * f=5.1 Std="SD" * f=5.2 Min="Min" * f=5.0 Max="Max" * f=5.0),
        
        /* --- COLUMNS --- */
        (TRT01P="Planned Treatment" ALL="Total")
        
        / box="Demographic Parameter" row=float misstext="0";
run;

title;

/* Fechar apenas o ficheiro Word */
ods rtf close;