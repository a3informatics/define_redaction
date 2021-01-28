*Reads in a define.xml and puts the contant into dataset:define in one column:ODM;
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

			data define;
				set define;
				length ODM_redacted $20000;
				ODM_redacted=ODM;
			run;

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

	data define;
		set define;

		if index(ODM,'StudyDescription') then
			do;
				ODM_redacted = tranwrd(ODM,scan(scan(ODM,2,'<'),2,'>'),cat("A REDACTED STUDY DESCRIPTION."," Phase:","&phase.",", TA:","&TA."));
			end;
	run;

%mend redact_update_study_description;

*Redacts study ID througout the whole file;
%macro redact_studyID;
	*Find studyID and study name;
	data _NULL_;
		set define;

		if index(ODM,'Study OID') then
			do;
				study=scan(ODM,2,'"');
				call symput('STUDY',strip(study));
			end;

		if index(ODM,'StudyName') then
			do;
				study_name=scan(scan(ODM,2,'<'),2,'>');
				call symput('STUDY_name',strip(study_name));
			end;
	run;

	%put &study;
	%put &study_name;

	*Redact the studyID and study name;
	data define;
		set define;
		ODM_redacted = tranwrd(ODM_redacted,"&STUDY","REDACTED STUDY");
		ODM_redacted = tranwrd(ODM_redacted,"&STUDY_name","REDACTED STUDY");
	run;

%mend redact_studyID;

*Redacts any test specified;
%macro redacttext(text,replace);

	data define;
		set define;
		ODM_redacted=tranwrd(ODM_redacted,"&text","&replace");
	run;

%mend;

%macro remove_extended_val(del_ext=&removed_extended_cl_val);
	%if &del_ext = Y %then
		%do;

			data define;
				set define;
				retain delete;
				length ext_val $40;

				if _n_=1 then
					delete=0;

				if delete=2 then
					delete=0;

				if (index(ODM,'<CodeListItem') and index(ODM,'def:ExtendedValue="Yes"')) or
					(index(ODM,'<EnumeratedItem') and index(ODM,'def:ExtendedValue="Yes"')) then
					delete=1;

				*Find the name/term of the extended value to be replaced with 'Redacted' in where clause;
				if index(ODM,'def:ExtendedValue="Yes"') then
					ext_val=compress(scan(scan(ODM,2,' '),2,'='),'"');

				if index(ODM,'</CodeListItem>') and delete then
					delete=2;
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
						ODM_redacted=tranwrd(ODM_redacted,"'||strip(ext_val)||'","REDACTED");
					run; ');
			run;

			data define;
				set define end=eof;
				retain deletemax;

				if delete>=deletemax then
					deletemax=delete;

				if eof and deletemax>0 then
					put "Extended values deleted";

				if eof and deletemax=0 then
					put "No extended values found in define";

				if not delete;
				drop delete deletemax ext_val;
			run;

		%end;
%mend remove_extended_val;

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

%macro redact_define(file_in, company_name=ACME, phase=NA, TA=NA, remove_comments=N, removed_extended_cl_val=N, remove_domains=, remove_CL=, redact_text=);
	%read_xml(&file_in);

	*Redact study ID from the file;
	%redact_studyID;

	*Redact and update study description;
	%redact_update_study_description(phase=&phase, TA=&TA)

	*Remove comments in all domains;
	%remove_comments(del_com=&remove_comments);

	*Remove extended values in code lists;
	%remove_extended_val(del_ext=&removed_extended_cl_val);

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

	*Extrating the path to be used for output;
	data _NULL_;
		filename="&file_in";
		path=substr(filename,1,find(filename,reverse(scan(reverse(filename),1,"\")))-1);
		call symput('path',strip(path));
	run;

	%put &path;

	*HASH convert company name. to be used in output filename;
	data _NULL_;
		hash=put(md5("&company_name."),$hex64.);
		name = cats("define_",hash,"_redact.xml");
		call symput('name',strip(name));
	run;

	%put &name;

	* The combined output name;
	%let file_out=%sysfunc(cats(&path.,&name.));
	%put &file_out;

	%write_xml(&file_out);
	%put Define file &file_in has been redacted and written to: &file_out.;
%mend redact_define;