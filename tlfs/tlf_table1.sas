/*******************************************************************************
Program Name: tlf_table1.sas
Description:  Generates Table 1: Demographics and Baseline Characteristics.
              Uses the ADSL dataset (Intent-to-Treat Population).
*******************************************************************************/

/* =====================================================================
   Ensure 00_setup.sas has been executed before running this script
   so that the adam library is active.
   ===================================================================== */

title1 "Table 1: Demographics and Baseline Characteristics";
title2 "Population: Intent-to-Treat (ITT)";

proc tabulate data=adam.adsl missing;
    /* Filter only randomized subjects */
    where ITTFL = 'Y'; 
    
    /* Categorical variables */
    class TRT01P SEX RACE; 
    
    /* Continuous variables */
    var AGE; 
    
    table 
        /* --- ROWS --- */
        N="Total Subjects"
        SEX="Sex" 
        RACE="Race"
        AGE="Age (years)" * (n*f=5.0 mean*f=5.1 std*f=5.2 min*f=5.0 max*f=5.0),
        
        /* --- COLUMNS --- */
        (TRT01P="Planned Treatment" ALL="Total")
        
        / box="Demographic Parameter" row=float misstext="0";
run;

title;