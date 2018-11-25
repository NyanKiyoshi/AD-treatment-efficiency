%INCLUDE '/folders/myfolders/MiniProjet/main.sas';

/* Import the dataset `adverse_event` */
DATA AE;
SET SOURCE.ADVERSE_EVENT
   SOURCE.DATE_OF_VISIT
   SOURCE.TREATMENT_ASSIGNMENT;

/* Pre-sort the data to ensure it's sorted by subject ID,
 * Otherwise we won't be able to merge the data later on. */
PROC SORT; BY USUBJID;

/* Retrieve the first visit per subject */
PROC SQL;
    create table firstVisits as
        select usubjid, visdt as firstVisitDt
        from SOURCE.DATE_OF_VISIT
        group by usubjid
        having visdt = min(visdt);
RUN;

/* Retrieve the last visit per subject */
PROC SQL;
    create table lastVisits as
        select usubjid, visdt as lastVisitDt
        from SOURCE.DATE_OF_VISIT
        group by usubjid
        having visdt = max(visdt);
RUN;

/* Create a `AE` dataset on the workspace */
DATA AE;

/* Merge the date of visit and the treatment groupe with the AE.
 * And ensure we keep the data ordered by subject identifier. */
MERGE
   SOURCE.ADVERSE_EVENT (IN=mark1)
   firstVisits (IN=mark2)
   lastVisits (IN=mark4)
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
IF mark1 AND ae_start_date >= firstVisitDt THEN OUTPUT;

RUN;

DATA AE_SUBJECT(where=(USUBJID='0560541'));
   SET AE;
   rowid=_n_;
   CALL SYMPUT('subject_id', USUBJID);
   CALL SYMPUT('ae_start_date', ae_start_date);
   CALL SYMPUT('lastVisitDt', lastVisitDt);
   CALL SYMPUT('firstVisitDt', firstVisitDt);
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
   
   /* Set the ticks of the reflines */
   scatter x=lastVisitDt y=rowid / markerattrs=(size=0px);
   scatter x=treatment_start_date y=rowid / markerattrs=(size=0px);
   
   /* Set the reflines for: last visit and treatment start date */
   refline lastVisitDt / axis=x lineattrs=(color=green thickness=3px) name='last_visit_line' legendlabel='Last visit';
   refline treatment_start_date / axis=x lineattrs=(color=orange thickness=3px) name='treatment_start' legendlabel='Treatment Start';

   /* Set the x axis values and grid with a per month interval */
   xaxis values=(&firstVisitDt to &lastVisitDt) grid type=time interval=month offsetmax=.1;

   /* Assign axis properties data extents and offsets to the y axis */
   yaxis display=(nolabel noticks novalues) min=0;

   /* Draw the legend */
   keylegend 'sev' / title='Severity:';
   discretelegend 'last_visit_line' 'treatment_start' / location=inside title='Legend' across=1;
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
