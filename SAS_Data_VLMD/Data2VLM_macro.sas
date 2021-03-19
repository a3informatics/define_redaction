* Extracts Value Level Metadata from SDTM SAS datasets
* to be used for creation of Biomedical Concepts.
*
* Responsible Programmer: Kirsten Walther Langendorf
* Date: 19-Mar-2021
;

* getting the domains with a TEST/TESTCD;
*reading in the relevant qualifiers based on FINDING CLASS variables from SDTM Model 1.8;
data qualifier;
	infile datalines delimiter=',' dsd;
	input name & $8. label & $40. role & $8.;
	datalines;
"TESTCD","Short Name of Measurement, Test, or Exam","Topic"
"TSTDTL","Measurement, Test, or Examination Detail","Variable"
"POS","Position of Subject During Observation","Record"
"BODSYS","Body System or Organ Class","Record"
"ORRES","Result or Finding in Original Units","Result"
"ORRESU","Original Units","Variable"
"RESCAT","Result Category","Variable"
"CHRON","Chronicity of Finding","Variable"
"DISTR","Distribution Pattern of Finding","Variable"
"RESLOC","Result Location of Finding","Result"
"SPEC","Specimen Material Type","Record"
"ANTREG","Anatomical Region","Variable"
"SPCCND","Specimen Condition","Record"
"SPCUFL","Specimen Usability for the Test","Record"
"LOC","Location Used for the Measurement","Record"
"LAT","Laterality","Variable"
"DIR","Directionality","Variable"
"PORTOT","Portion or Totality","Variable"
"METHOD","Method of Test or Examination","Record"
"ANMETH","Analysis Method","Record"
"LEAD","Lead Identified to Collect Measurements","Record"
"CSTATE","Consciousness State","Record"
"FAST","Fasting Status","Record"
"DRVFL","Derived Flag","Record"
"EVAL","Evaluator","Record"
"EVALID","Evaluator Identifier","Variable"
"TOX","Toxicity","Variable"
"TOXGR","Toxicity Grade","Record"
"SEV","Severity","Record"
"DTHREL","Relationship to Death","Record"
"LLOQ","Lower Limit of Quantitation","Variable"
"ULOQ","Upper Limit of Quantitation","Variable"
"OBJ","Object of the Observation","Record"
"CAT","Category","Grouping"
"SCAT","Subcategory","Grouping"
run;

%macro VLMD_data(indata, TA=, phase=, out=);
	%if (%str(&indata) = %str() or %str(&out) = %str()) %then
		%do;
			%put %str(ER)ROR: One or both of the input parameters "indata" and "out" were not specified;
			%put %str(ER)ROR: Exiting macro VLMD_data(&indata.,out=&OUT.);
			%goto exit;
		%end;

	*finding the right qualifiers for the datasets in the library;
	proc sql;
		create table tmp as
			select a.memname as table,
				a.name as column
			from sashelp.vcolumn a, work.qualifier b
				where substr(a.name,3)=b.name
					and a.libname="INDATA"
					and memname not contains "TI";
	quit;

	proc sql;
		create table init as
			select a.*
				from tmp a, work.tmp b
					where a.table=b.table
						and b.column contains "TESTCD";
	quit;

	data init;
		set init;
		length label $200 order 8 type $1 length 8 displayformat $200 significantdigits 8 xmldatatype $18;
	run;

	proc sort data=init;
		by table column;
	run;

	proc sql noprint;
		select distinct	table
			,	column 
		into	:domains	separated by "�"
			,	:vars 		separated by "�"

		from init
			where substr(column,3) not in('TESTCD', 'ORRES', 'ORRESU');
		;
	quit;

	proc sql noprint;
		select distinct	name, name, "'"||STRIP(name)||"'" 
			into	:varlist 		separated by " "
				,   :varlistc       separated by ","
				,   :varlisth       separated by ","
			from work.qualifier
				where name not in ('TESTCD', 'ORRESU', 'ORRES')
		;
	quit;

	%put domains=&domains;
	%put vars=&vars;
	%put varlist=&varlist;
	%put varlistc=&varlistc;

	******************************
	* SECTION 01 *****************
	******************************;

	* Create metadata for an empty table, preparing for filling in data from 
	* the relevant tables;
	data rel_proj_data;
		length table $6 column $8 test $8 value $8 values $39 label $200 unit $7 %lowcase(&varlist) $200;
		stop;
	run;

	* Run through the extracted tables one by one, and extract all available data;
	%do i=1 %to %sysfunc(countw(&domains.,�));
		%let domain = %scan(&domains.,&i.,�);
		%let var	= %scan(&vars.,&i.,�);

		/* Get list of variable names */
		%let varnames=;

		/* Append variable name one by one for all variables in dataset */
		%let dsid = %sysfunc( open(indata.&domain) );

		%do j=1 %to %sysfunc( attrn(&dsid,nvars) );
			%let varnames = &varnames. %sysfunc(varname(&dsid.,&j.));
		%end;

		%let rc = %sysfunc(close(&dsid));

		/* Upcase varnames, and use the var names as a reference list to
		   adapt the SQL script, to what variables are in the current domain */
		%let varnames = %upcase(&varnames.);

		*If ORRES is blank then take the value from STRESC - cases in QS domain;
		data tmp;
			set indata.&domain;

			/*	if &domain.ORRES='' and &domain.STRESC ne '' then
						&domain.ORRES=&domain.STRESC;*/
		run;

		proc sql;
			create table temp as
				select distinct	domain			as table	length=6
					,	catt(domain,"TESTCD")	as test		length=8
					,	catt(domain,"ORRES")	as column	length=8
					,	&domain.TESTCD			as value	length=8
					,	&domain.ORRES	    	as values	length=39	
					,	&domain.TEST			as label	length=200
					%IF %SYSFUNC(index(&varnames,&domain.ORRESU))>0 %THEN

				%DO;
					,	&domain.ORRESU			as unit 	length=7
				%END;
	%ELSE
		%DO;
			,	''						as unit		length=7
		%END;

	%do k=1 %to %sysfunc(countw(&varnames.,' '));
		%let param=%SYSFUNC(substr(%scan(&varnames.,&k.,' '),3));

		%IF %SYSFUNC(findw(&varlist,&param))>0 %THEN
			%DO;
				,  &domain.&param as &param length=80
			%END;
	%end;

	from tmp
		order by table, value
	;
		quit;

		data temp;
			if 0 then
				set work.rel_proj_data;
			set temp;
		run;

		proc append data=temp base=rel_proj_data;
		run;

	%end;

	data basis_data;
		* Set up columns and attributes for this table;
		if 0 then
			set init;
		length value $32;

		if 0 then
			set init;

		* Merge;
		merge init(keep=table column) rel_proj_data(in=right_table);
		by table column;

		* Right join init with rel_proj_data;
		if right_table;
	run;

	proc sort data=work.basis_data;
		by table column label value unit &varlist;
	run;

	******************************
	* SECTION 02 *****************
	******************************;
	proc sql;
		/* Find combinations of table, value, cat, subcat, spec with more than one method */
		create table keys_with_non_unique_methods as
			select table, column, label, value, unit, &varlistc
				from (
					/* Find unique combinations of the key */
				select distinct table, column, label, value, unit, &varlistc
					from work.basis_data
						where method ne ''
							)
						group by table, column, label, value, unit, &varlistc
							having count(*)>1
		;
	quit;

	%let keys = 'table','column','label','value',&varlisth;

	* Write extracted information to source values table;
	data source_values_tmp;
		set basis_data;
		by table column label value unit &varlist;
		length whereclause $1000;
		retain c_cand f_cand all_missing digits order_n len_var;

			* Make use of hash object to keep track of key combinations where method;
			* has more than one value;
			if _n_=1 then
				do;
					declare hash h(dataset:'keys_with_non_unique_methods');
					h.defineKey(&keys.);
					h.defineDone();
				end;

			* For every domain, keep track of the order of the variables;
			if first.table then
				order_n = 0;

			if first.value then
				do;
					all_missing = 1;

					* Variable values have;
					c_cand 		= 0;

					* Character candidate;
					f_cand 		= 0;

					* Float candidate;
					digits		= 0;

					* Number of digits for given float number;
					len_var		= 0;

					* Minimal length of character variable to show all data;
				end;

			* Check first and foremost if value is missing;
			if not missing(values) then
				do;
					all_missing = 0;

					* Find shortest possible representation that includes all information;
					len_var = max(length(values), len_var);

					* Find out whether current value is a candidate for character or numeric;
					* If data value is "-" or a "-" character occurs in a position other than the first,;
					* this is a character candidate;
					if strip(values) = "-" or ( countc(substr(left(values),2),'-')>0 or countc(values,'+','a')>0 ) then
						c_cand = 1;

					* Find out if numeric value is an integer or a float - and determine number of digits.
					* This is constantly updated to give the maximum number of digits for all numbers;
					else if mod(input( compress(values,'<>') ,best32.),1) ne 0 then
						do;
							f_cand = 1;
							digits = max(digits, length(scan(values,2,'.,')) );
						end;
				end;

			* When last value for a domain is reached, metadata is filled in and output;;
			if last.value then
				do;
					* Update order of variables and write it into the final table;
					order_n + 1;
					order = order_n;

					* Check candidate types and set the datatype accordingly;
					if all_missing then
						do;
							putlog "WA" "RNING: No non-missing data found for " table= column= value=;
							putlog "WA" "RNING: No value level metadata will be created for this combination";
							delete;
						end;
					else if c_cand then
						do;
							xmldatatype = 'text';
							type 		= 'C';
							length		= len_var;
						end;
					else if f_cand then
						do;
							xmldatatype 	= 'float';
							type 			= 'N';
							length			= len_var;
							displayformat	= compress(len_var!!'.'!!digits);
							significantdigits=digits;
						end;
					else
						do;
							xmldatatype = 'integer';
							type 		= 'N';
							length		= len_var;
						end;

					*Creating the whereclause column;
					whereclause='('||strip(test)||' EQ "'||strip(value)||'")';

					* Prepare for building whereclause;
					%let nkeys=%eval(%sysfunc(countw(&varlist, %str( ))));
					array txts	   {*} $ &varlist;
					array txts_tmp { &nkeys} $ _TEMPORARY_ (&varlisth);

					* Build whereclause of the columns mentioned above, where these are not missing;
					do _i=1 to dim(txts);
						if not missing(txts{_i}) then
							whereclause = catx(' AND ', whereclause, '('||strip(table)||strip(txts_tmp{_i})||' EQ "'||strip(txts{_i})||'")' );
					end;

					* Add "method" to whereclause, but only when method is unique to the current key;
					* This is determined with help from the hashobject created in the top of the datastep;

					*if h.find()=0 and whereclause ne "" then
											whereclause=catx(' AND ',whereclause,'('||strip(table)||'METHOD EQ "'||strip(method)||'")');

					* Output row;
					output;
				end;
	run;

	data OBS_CD;
		set work.source_values_tmp;
		where type='C';
	run;

	proc sql;
		create table responses as 
			select distinct a.table, a.column, a.value, a.values
				from work.basis_data a, work.obs_cd b
					where a.table=b.table
						and a.column=b.column
						and a.value=b.value;
	quit;

	proc sql;
		create table obs_cd_all as
			select a.*, b.values as new_values
				from obs_cd a left join responses b
					on a.table=b.table
					and a.column=b.column
					and a.value=b.value;
	quit;

	data obs_cd;
		set obs_cd_all;
		values=new_values;
		drop new_values;

	data obs_pqr_int;
		set work.source_values_tmp;
		where type='N';
	Run;

	data source_values;
		set work.obs_cd obs_pqr_int;
		drop  _i all_missing c_cand digits f_cand order_n order len_var
		;
	run;

	*Adding TA and phase as first columns if provided,reordering columns and sorting;
	proc sql;
		create table VLMD as
			select "&TA" as TA, 
				"&phase" as PHASE,
				table, 
				column, 
				label, 
				type, 
				length, 
				displayformat, 
				significantdigits, 
				xmldatatype, 
				value, 
				test, 
				values, 
				unit, 
				whereclause, 
				&varlistc
			from source_values
				order by table, column, value;
	quit;

	*cleanup work;
	proc sql noprint;
		select cats('WORK.',memname) into :to_delete separated by ' '
			from dictionary.tables
				where libname = 'WORK' and memname not in('QUALIFIER', 'VLMD');
	quit;

	proc delete data=&to_delete.;
	run;

	*UPCASE all variables;
%macro uppercase(dsn);
	%let dsid=%sysfunc(open(&dsn));
	%let num=%sysfunc(attrn(&dsid,nvars));
	%put &num;

	data &dsn;
		set &dsn(rename=( 
		%do i = 1 %to &num;
		/*function of varname returns the name of a SAS data set variable*/
		%let var&i=%sysfunc(varname(&dsid,&i));
		&&var&i=%sysfunc(upcase(&&var&i)) /*rename all variables*/
		%end;));
		%let close=%sysfunc(close(&dsid));
	run;

%mend uppercase;

%uppercase(VLMD);

*Export dataset to excel;
*If out is not set then set to default value;
proc export 
	data=VLMD
	dbms=xlsx
	outfile="&out"
	replace;
run;

%exit:
%mend VLMD_data;
