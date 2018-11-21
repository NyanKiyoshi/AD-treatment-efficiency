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

/* Retrieve what year we are today as constant */
CURRENT_YEAR = YEAR(INPUT("&sysdate9", date9.));

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

RUN;

DATA AE_SUBJECT(where=(USUBJID='0560541'));
	SET AE;
  	rowid=_n_;
RUN;

/*--Custom style for severity of events--*/
proc template;
   define Style AETimeline; parent = styles.listing;
      style GraphColors from graphcolors /
           "gcdata" = cx000000
           "gcdata1" = cx1fcf1f
           "gcdata2" = cxdfbf1f
           "gcdata3" = cxbf1f1f;
      style GraphFonts from GraphFonts /                                   
         'GraphDataFont' = ("<sans-serif>, <MTsans-serif>",5pt)  
         'GraphValueFont' = ("<sans-serif>, <MTsans-serif>",7pt) 
         'GraphTitleFont' = ("<sans-serif>, <MTsans-serif>",11pt);  
   end;
run;

title 'Adverse Events for Patient Id = #USUBJID';
ods listing style=AETimeline image_dpi=100;
ods graphics / reset width=5in height=3in imagename="Fig12_5_AE_Timeline_V92";
proc sgplot data=AE_SUBJECT noautolegend nocycleattrs;
   refline 0 / axis=x lineattrs=(thickness=1 color=black);

   /*--Draw the events--*/
   vector x=ae_stop_date y=rowid / xorigin=ae_start_date yorigin=rowid noarrowheads lineattrs=(thickness=9px);
   vector x=ae_stop_date y=rowid / xorigin=ae_start_date yorigin=rowid noarrowheads lineattrs=(thickness=7px pattern=solid) 
        transparency=0 group=aesev  name='sev';

   /*--Draw start and end events--*/
   scatter x=ae_start_date y=rowid / markerattrs=(size=13px symbol=circlefilled); 
   scatter x=ae_start_date y=rowid / markerattrs=(size=11px symbol=circlefilled) group=aesev;
   scatter x=ae_start_date y=rowid / markerattrs=(size=13px symbol=circlefilled); 
   scatter x=ae_start_date y=rowid / markerattrs=(size=11px symbol=circlefilled) group=aesev;

   /*--Draw the event name using non-proportional font--*/ 
   /*scatter x=ae_start_date y=rowid / markerchar=buffer markercharattrs=(family='Lucida Console' size=9);*/

   /*--Assign dummy plot to create independent X2 axis--*/
   scatter x=ae_start_date y=rowid /  markerattrs=(size=0) x2axis;

/*
   /*--Assign axis properties data extents and offsets--*//*
   yaxis display=(nolabel noticks novalues) min=0;
   xaxis grid label='Study Days' offsetmin=0.1 offsetmax=0.02 
         values=(&minday2 to &maxday by 2);
   x2axis notimesplit display=(nolabel) offsetmin=0.1 offsetmax=0.02 
         values=(&mindate2 to &maxdate);*/

   /*--Draw the legend--*/
   keylegend 'sev'/ title='Severity :';
run;







RUN;
