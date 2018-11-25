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
FORMAT ae_start_date ae_stop_date treatment_start_date ddmmyyd10.;

/* Copy dates to our custom variables */
ae_start_date = AESTDT;
ae_stop_date = AEENDT;
treatment_start_date = datepart(ASGNDTTM);

/* Default the start date to the 1st January of the current year */
if ae_start_date=. then do;
   ae_start_date = MDY(01, 01, AESTDTYY);
end;

/* Default the stop date to the 31st December of the current year */
if ae_stop_date=. then do;
   ae_stop_date = MDY(12, 31, IFN(AEENDTYY, AEENDTYY, AESTDTYY));
end;

/* If the latest visit wasn't prior the start date, we can output it */
IF mark1 AND VISDT >= ae_start_date THEN OUTPUT;

RUN;

DATA AE_SUBJECT(where=(USUBJID='0560541'));
   SET AE;
   rowid=_n_;
   CALL SYMPUT('subject_id', USUBJID);
RUN;

PROC SORT; BY ae_start_date;
RUN;

title "Adverse Events for Patient Id = &subject_id";
ods graphics / reset width=8in height=6in;
proc sgplot data=AE_SUBJECT noautolegend nocycleattrs;
   /*--Draw the events--*/
   vector x=ae_stop_date y=rowid / xorigin=ae_start_date yorigin=rowid noarrowheads lineattrs=(thickness=9px) transparency=0 group=aesev name='sev';

   /*--Draw start and end events--*/
   scatter x=ae_start_date y=rowid / markerattrs=(size=9px symbol=circlefilled) group=aesev datalabel=aeterm;
   scatter x=ae_stop_date y=rowid / markerattrs=(size=9px symbol=circlefilled) group=aesev;
   
   scatter x=VISDT y=rowid / markerattrs=(size=13px symbol=diamondfilled color=coral) name='visdt' legendlabel='Last Visit';
   scatter x=treatment_start_date y=rowid / markerattrs=(size=13px symbol=starfilled color=goldenrod) name='trtst' legendlabel='Treatment Start';

   /* Assign the plot to create a x2 axis */
   scatter x=ae_start_date y=rowid /  markerattrs=(size=0) x2axis;

   /* Assign axis properties data extents and offsets to the y axis */
   yaxis display=(nolabel noticks novalues) min=0;

   /* Draw the legend */
   keylegend 'sev' / title='Severity:';
   discretelegend 'visdt' 'trtst' / location=inside title='Legend' across=1;
RUN;

ods graphics / reset width=8in;
PROC SGPANEL DATA=AE;
   PANELBY TRTDESC / NOVARNAME COLUMNS=3;
   HBAR SOCTERM / STAT=FREQ nostatlabel CATEGORYORDER=RESPDESC baselineattrs=(thickness=0) seglabel seglabelattrs=(size=7);
   rowaxis display=(noline nolabel) valueattrs=(size=7);
RUN;

PROC FREQ DATA=AE;
    TABLES SOCTERM * TRTCD;
RUN;
