*Reads in a define.xml and puts the contant into dataset:define in one column:ODM;
%global nrows;
 
%macro read_xml(filein);
    %if %length(&filein)=0 %then
        %put "Please specify path/filename of define file";
    %else
        %do;

            data define;
                infile "&filein." length=len;
                input ODM $varying20000. len;
                output;
            run;

            data _NULL_;
                if 0 then
                    set define nobs=n;
                call symputx('nrows',n);
                stop;
            run;

            %put Number of rows read from &filein = &nrows;
        %end;
%mend read_xml;

*Writes the dataset define out into a file containing the redacted define.xml (column:ODM_redacted);
%macro write_xml(fileout);
    %if %length(&fileout)=0 %then
        %put "Please specify path/filename of define file";
    %else
        %do;

            data _NULL_;
                set define(keep=ODM_redacted);
                file "&fileout.";
                put ODM_redacted;
            run;

        %end;
%mend write_xml;

*Redacts study description and adds info on phase and TA to the description;
%macro redact_update_study_description(phase=, TA=);
    *Finds lines between <StudyDescription> and </StudyDescription> and puts redact=1, 
    last row has redact=2. Deletes all lines with redact=1
    and replace line with redact=2 with the REDACTED STUDY info;
    data define;
        set define;
        retain redact;

        if _n_=1 then
            redact=0;

        if redact=2 then
            redact=0;

        if index(ODM,'<StudyDescription') then
            redact=1;

        if (index(ODM,'</StudyDescription') and redact) then
            redact=2;
    run;

    data define;
        set define;

        if redact=2 then
            do;
                ODM_redacted = cat("<StudyDescription>","A REDACTED STUDY DESCRIPTION."," Phase:","&phase.",", TA:","&TA.","</StudyDescription>");
                redact=0;
            end;

        if not redact;
        drop redact;
    run;

%mend redact_update_study_description;

*Redacts study ID througout the whole file;
%macro redact_studyID;
    *Find studyID and study name;
    %let study=;
    %let study_name=;
    %let prot_name=;

    data _NULL_;
        set define;

        if index(ODM,'Study OID') then
            do;
                study=scan(ODM,2,'"');
                call symput('STUDY',strip(study));
            end;

        if index(ODM,'<StudyName') then
            do;
                study_name=scan(scan(ODM,1,'</'),2,'>');
                call symput('STUDY_name',strip(study_name));
            end;

        if index(ODM,'<ProtocolName') then
            do;
                prot_name=scan(scan(ODM,1,'</'),2,'>');
                call symput('prot_name',strip(prot_name));
            end;
    run;

    %put Study OID = &study;
    %put StudyName = &study_name;
    %put ProtocolName = &prot_name;

    *Redact the studyID, protcol name and study name;
    data define;
        set define;

        %if %length(&study)=0 %then
            %do;
                put "Study ID was not extracted";
            %end;
        %else
            %do;
                ODM_redacted = tranwrd(ODM_redacted,"&STUDY","REDACTED STUDY");
            %end;

        %if %length(&study_name)=0 %then
            %do;
                put "Study Name was not extracted";
            %end;
        %else
            %do;
                ODM_redacted = tranwrd(ODM_redacted,"&STUDY_name","REDACTED STUDY");
            %end;

        %if %length(&prot_name)=0 %then
            %do;
                put "Protocol Name was not extracted";
            %end;
        %else
            %do;
                ODM_redacted = tranwrd(ODM_redacted,"&prot_name","REDACTED STUDY");
            %end;
    run;

%mend redact_studyID;

*Redacts any test specified;
%macro redacttext(text,replace);

    data define;
        set define;
        ODM_redacted=tranwrd(ODM_redacted,"&text","&replace"||&rs.);
    run;

%mend;


%macro redact_extended_val(red_ext=&redact_extended_cl_val);

    %if &red_ext = Y %then
        %do;

            data define;
                set define;
                retain redact;
                length ext_val $200;

                if _n_=1 then
                    redact=0;

                if redact=2 then
                    redact=0;

                if (index(ODM,'<CodeListItem') and index(ODM,'def:ExtendedValue="Yes"')) or
                    (index(ODM,'<EnumeratedItem') and index(ODM,'def:ExtendedValue="Yes"')) then
                    redact=1;

                *Find the name/term of the extended value to be replaced with 'Redacted' in where clause;
                if index(ODM,'def:ExtendedValue="Yes"') then
                    ext_val=scan(ODM,2,'"');
                    
                if redact then do;
                    if index(ODM,"<CodeListItem") then 
                        ODM_redacted=tranwrd(ODM_redacted,'"'||strip(ext_val)||'"','"REDACTED'||&rs.||'"');
                    if index(ODM,"<TranslatedText") then
                        ODM_redacted="<TranslatedText>REDACTED"||&rs.||"</TranslatedText>";
                    if index(ODM,"<EnumeratedItem") then
                        ODM_redacted='<EnumeratedItem CodedValue="REDACTED'||&rs.||'"/>';
                end;

                if (index(ODM,'</CodeListItem>') OR index(ODM,"<EnumeratedItem")) and redact then
                    redact=2;
            run;

            proc sql;
                create table ext_value as
                    select distinct ext_val from define(where=(ext_val ne ''));
            quit;

            data _NULL_;
                set ext_value;
                call execute('data define;
                    set define;
                    if index(ODM,"<CheckValue>") then
                        ODM_redacted=tranwrd(ODM_redacted,"'||strip(ext_val)||'","REDACTED'||&rs.||'");');
                    run; 
            run;

        %end;
%mend redact_extended_val;


%macro remove_comments(del_com=&remove_comments);
    %if &del_com = Y %then
        %do;

            data define;
                set define;
                retain delete;

                if _n_=1 then
                    delete=0;

                if delete=2 then
                    delete=0;

                if index(ODM,'<def:CommentDef') then
                    delete=1;

                if (index(ODM,'</def:CommentDef') and delete) then
                    delete=2;
            run;

            data define;
                set define end=eof;
                retain deletemax;

                if delete>=deletemax then
                    deletemax=delete;

                if eof and deletemax>0 then
                    put "Comments deleted";

                if eof and deletemax=0 then
                    put "No comments found in define";

                if not delete;
                drop delete deletemax;
            run;

        %end;
%mend remove_comments;

%macro delete_domain(domain);

    data define;
        set define;
        retain delete;

        if _n_=1 then
            delete=0;

        if delete=2 then
            delete=0;

%macro rep(dm);
    if (index(ODM,'<def:ValueListDef') and index(ODM,"OID=""VL.&dm")) or
        (index(ODM,'<def:WhereClauseDef') and index(ODM,"OID=""WC.&dm")) or
        (index(ODM,'<ItemGroupDef') and index(ODM,"OID=""IG.&dm")) or
        (index(ODM,'<ItemDef') and index(ODM,"OID=""IT.&dm")) then
        delete=1;

    if (index(ODM,'</def:ValueListDef') or
        index(ODM,'</def:WhereClauseDef') or
        index(ODM,'</ItemGroupDef') or
        index(ODM,'</ItemDef') )and delete then
        delete=2;
%mend rep;

*Deletes domain+suppdomain;
%rep(&domain);
%rep(SUPP&domain);

data define;
    set define;

    if not delete;
    drop delete;
run;

%mend delete_domain;

%macro delete_CL(codelist);

    data define;
        set define;
        retain delete;

        if _n_=1 then
            delete=0;

        if delete=2 then
            delete=0;

        if (index(ODM,'<CodeList ') and index(ODM,"OID=""CL.&codelist""")) then
            delete=1;

        if (index(ODM,'</CodeList>')) and delete then
            delete=2;
    run;

    data define;
        set define;

        if index(ODM,"<CodeListRef CodeListOID=""CL.&codelist""") then
            delete=1;
    run;

    data define;
        set define end=eof;
        retain deletemax;

        if delete>=deletemax then
            deletemax=delete;

        if eof and deletemax>0 then
            put "Code list: &codelist deleted";

        if eof and deletemax=0 then
            put "No code list: &codelist found in define";

        if not delete;
        drop delete deletemax;
    run;

%mend delete_CL;

%macro redact_define(file_in, output_suffix=, 
                     company_name=ACME, 
                     phase=NA, 
                     TA=NA, 
                     remove_comments=N, 
                     redact_extended_cl_val=N, 
                     rs='['||strip(_n_)||']',
                     remove_domains=, 
                     remove_CL=, 
                     redact_text=
                     );
    
    %read_xml(&file_in);
    
    * remove any blank lines;
    data define;
        set define;

        if _N_=1 then
            do;
                ODM2=ODM;
                ODM2='';
            end;

        retain ODM2;
        drop ODM2;

        if substr(strip(reverse(ODM)),1,1)='>' then
            do;
                ODM=strip(strip(ODM2)||' '||strip(ODM));
                ODM2='';
                output;
            end;
        else ODM2=strip(strip(ODM2)||' '||strip(ODM));
    run;

        data _NULL_;
                if 0 then
                    set define nobs=n;
                call symputx('nrows_collaps',n);
                stop;
            run;

            %put Number of rows in define after removing returns = &nrows_collaps;
            %put Number of returns deleted = %eval(&nrows-&nrows_collaps);

    data define;
        set define;
        length ODM_redacted $20000;
        ODM_redacted=ODM;
    run;

    *Redact study ID from the file;
    %redact_studyID;

    *Redact and update study description;
    %redact_update_study_description(phase=&phase, TA=&TA)

    *Remove comments in all domains;
    %remove_comments(del_com=&remove_comments);

    *Redact extended values in code lists;
    %redact_extended_val(red_ext=&redact_extended_cl_val);


    *Remove domains;
    %if %length(&remove_domains)> 0 %then
        %do;
            %do i=1 %to %sysfunc(countw("&remove_domains."));
                %let domain = %scan(&remove_domains., &i);

                %delete_domain(&domain);
            %end;
        %end;

    *Remove Code Lists;
    %if %length(&remove_CL)> 0 %then
        %do;
            %do i=1 %to %sysfunc(countw("&remove_CL."));
                %let CL = %scan(&remove_CL., &i);

                %delete_CL(&CL);
            %end;
        %end;

    *Redact specified text;
    %if %length(&redact_text)> 0 %then
        %do;

            data _NULL_;
                count=countw("&redact_text",' ','q');
                call symput('count',count);
            run;

            %do i=1 %to &count;
                %let text = %sysfunc(scan(&redact_text.,&i,' ',q));
                %let txt = %sysfunc(dequote(&text));

                %redacttext(&txt,Redacted text);
            %end;
        %end;
%put SYSSCP is &SYSSCP;
    *Extracting the path to be used for output;
   %if &SYSSCP = WIN %then %do;
    data _NULL_;
        filename="&file_in";
        path=substr(filename,1,find(filename,reverse(scan(reverse(filename),1,"\")))-1);
        call symput('path',strip(path));
    run;
	%end;
	%else %do;
	data _NULL_;
        filename="&file_in";
        path=substr(filename,1,find(filename,reverse(scan(reverse(filename),1,"/")))-1);
        call symput('path',strip(path));
    run;
	%end;

    %put &path;

    *HASH convert company name. to be used in output filename;
    data _NULL_;
        name = cats("define_","&output_suffix","_redact.xml");
        call symput('name',strip(name));
    run;

    %put &name;

    * The combined output name;
    %let file_out=%sysfunc(cats(&path.,&name.));
    %put &file_out;

    %write_xml(&file_out);
    %put Define file &file_in has been redacted and written to: &file_out.;
%mend redact_define;
