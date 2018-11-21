%INCLUDE '/folders/myfolders/MiniProjet/main.sas';

/* Import the dataset `adverse_event` */
DATA AE;
SET SOURCE.ADVERSE_EVENT
    SOURCE.DATE_OF_VISIT 
    SOURCE.TREATMENT_ASSIGNMENT;

/* Pre-sort the data to ensure it's sorted by subject ID,
 * Otherwise we won't be able to merge the data later on. */
PROC SORT; BY USUBJID;

/* Create a `AE` dataset on the workspace */
DATA AE;

/* Merge the date of visit and the treatment groupe with the AE.
 * And ensure we keep the data ordered by subject identifier. */
MERGE
    SOURCE.ADVERSE_EVENT (IN=mark1) 
    SOURCE.DATE_OF_VISIT (IN=mark2)
    SOURCE.TREATMENT_ASSIGNMENT(IN=mark3); 
    BY USUBJID;

/* Declare the date variables */
FORMAT ae_start_date ae_stop_date ddmmyyd10.;
CURRENT_YEAR = year(input("&sysdate9",date9.));

/* Copy dates to our custom variables */
ae_start_date = AESTDT;
ae_stop_date = AEENDT;

/* Default the start date to the 1st January of the current year */
if ae_start_date=. then do;
    ae_start_date = MDY(01, 01, CURRENT_YEAR);
end;

/* Default the stop date to the 31st December of the current year */
if ae_stop_date=. then do;
    ae_stop_date = MDY(12, 31, CURRENT_YEAR);
end;

/* If the latest visit wasn't prior the start date, we can output it */
IF mark1 AND VISDT >= ae_start_date THEN OUTPUT;

/* We are done here! We run. */
RUN;

