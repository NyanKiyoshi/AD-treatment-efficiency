%INCLUDE '/folders/myfolders/MiniProjet/main.sas';

ODS SELECT Variables;
PROC CONTENTS DATA=source.adverse_event;
   TITLE 'The Contents of the ADVERSE_EVENT Data Set';

ODS SELECT Variables;
PROC CONTENTS DATA=source.DATE_OF_VISIT ;
   TITLE 'The Contents of the DATE_OF_VISIT Data Set';

ODS SELECT Variables;
PROC CONTENTS DATA=source.DEMOGRAPHY;
   TITLE 'The Contents of the DEMOGRAPHY Data Set';

ODS SELECT Variables;
PROC CONTENTS DATA=source.MMSE_RESULT;
   TITLE 'The Contents of the MMSE_RESULT Data Set';

ODS SELECT Variables;
PROC CONTENTS DATA=source.PHYSICAL_EXAM;
   TITLE 'The Contents of the PHYSICAL_EXAM Data Set';

ODS SELECT Variables;
PROC CONTENTS DATA=source.TREATMENT_ASSIGNMENT;
   TITLE 'The Contents of the TREATMENT_ASSIGNMENT Data Set';

ODS SELECT Variables;
PROC CONTENTS DATA=source.VITAL_SIGNS;
   TITLE 'The Contents of the VITAL_SIGNS Data Set';

ODS SELECT Variables;
RUN;
