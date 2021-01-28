*Do not delete below
Note that this file is assuned to be in same folder as the this program.;
   %macro program_path();
	%LOCAL full_path path;

	%let full_path = ;

	/******************************
	 * Section 1 ******************
	 ******************************/

	/* Find the full path (including filename) of the file that is running */
	%IF &SYSPROCESSMODE.=SAS DMS Session %THEN %DO;				/* Display Manager */
		%LET full_path = %sysget(SAS_EXECFILEPATH);
	%END;
	%ELSE %IF &SYSPROCESSMODE.=SAS Batch Mode %THEN %DO;		/* Batch mode */
		%LET full_path = %sysfunc(getoption(sysin));
	%END;
    %ELSE %IF &SYSPROCESSMODE.=SAS Workspace Server %THEN %DO;	/* Enterprise Guide/SAS Studio */
		%LET full_path = %sysfunc(dequote(%str(&_SASProgramfile)));
	%END;
	%ELSE %DO;
		%PUT %str(ER)ROR: Unexpected SAS Environment - use SAS Display Manager, EG or Batch mode;
		%GOTO exit;
	%END;

	/******************************
	 * Section 2 ******************
	 ******************************/

	%let path = ;
	%IF %LENGTH(&full_path.) > 0 %THEN %DO;
		/* Extract the full path, by leaving out the filename */
	    %LET path = %substr(&full_path.,1, %sysfunc(findc(&full_path.,\\,-%length(&full_path.)))-1);
	%END;
	%ELSE %DO;
		%PUT %STR(ER)ROR: No program path could be extracted - the executing program seems to be temporary;
		%PUT %STR(ER)ROR: program_path_v01 needs to run from a physically saved program to function properly;
		%GOTO exit;
	%END;

	%exit:

	/* Return path as text */
    &path.
%mend program_path;

%include "%program_path()\RedactMacros.sas";


*Redact all study details
studyname will be set to: REDACTED STUDY
study description will be set to: A REDACTED STUDY DESCRIPTION

1. Specify the path\name of the input define.xml file.
2. Specify company name - will be used in the name of the redacted defie.xml as a hash value, e.g. define_ 3fbeb6a5a3e2f60d2a9c015a6f527a08 _redact.xml
3. Specify phase of the study  - for define.xml miner tool to do statistics. See terminology below(Submission value). 
Will be added to redacted study description: <StudyDescription>A redacted study description. Phase:3, TA:Asthma</StudyDescription>
4. Specify Therapeutic Area of the study  - for define.xml miner tool to do statistics. See terminology at the bottom of this file. 
5. Specify if all comments are to be removed, default is N.
6. Specify if extended code list values should be removed. Default is N
7. Specify the list of domains to remove is any. Default is blank.
8. Specify if any code lists are to be removed.
9. Specify if any other text must be redacted. Use quotes if text contains space;
%redact_define(S:\Glandon\BCMiner\define-sdtm-3.1.2.xml, 
               company_name=CDISC, 
               phase=PHASE III TRIAL, 
               TA=%bquote(Alzheimer's), 
               remove_comments=Y, 
               removed_extended_cl_val=Y, 
               remove_domains=IE FA,
               remove_CL=IETEST IETESTC, 
               redact_text='Miracle Drug' WONDER);
      
*example of no comments and extended values are to be removed and no domains and codelists. Only study ID and study description will be removed.;
*%redact_define(S:\Glandon\BCMiner\define.xml, company_name=ACME, phase=PHASE I TRIAL, TA=Asthma, redact_text= );

*Trial Phase to use: We use the CDISC term:
TPHASE (C66737)
SUBMISSION VALUE   Definition	
NOT APPLICABLE	   Determination of a value is not relevant in the current context. (NCI)
PHASE I TRIAL	   The initial introduction of an investigational new drug into humans. Phase 1 studies are typically closely monitored and may be conducted in patients or normal volunteer subjects. NOTE: These studies are designed to determine the metabolism and pharmacologic actions of the drug in humans, the side effects associated with increasing doses, and, if possible, to gain early evidence on effectiveness. During Phase 1, sufficient information about the drug's pharmacokinetics and pharmacological effects should be obtained to permit the design of well-controlled, scientifically valid, Phase 2 studies. The total number of subjects and patients included in Phase I studies varies with the drug, but is generally in the range of 20 to 80. Phase 1 studies also include studies of drug metabolism, structure-activity relationships, and mechanism of action in humans, as well as studies in which investigational drugs are used as research tools to explore biological phenomena or disease processes. [After FDA CDER Handbook, ICH E8] (CDISC glossary)
PHASE I/II TRIAL   A class of clinical study that combines elements characteristic of traditional Phase I and Phase II trials. See also Phase I, Phase II.
PHASE II TRIAL	   Phase 2. Controlled clinical studies conducted to evaluate the effectiveness of the drug for a particular indication or indications in patients with the disease or condition under study and to determine the common short-term side effects and risks associated with the drug. NOTE: Phase 2 studies are typically well controlled, closely monitored, and conducted in a relatively small number of patients, usually involving no more than several hundred subjects. [After FDA CDER Handbook, ICH E8] (CDISC glossary)
PHASE II/III TRIAL A class of clinical study that combines elements characteristic of traditional Phase II and Phase III trials.
PHASE IIA TRIAL	   A clinical research protocol generally referred to as a pilot or feasibility trial that aims to prove the concept of the new intervention in question. (NCI)
PHASE IIB TRIAL	   A clinical research protocol generally referred to as a well-controlled and pivotal trial that aims to prove the mechanism of action of the new intervention in question. A pivotal study will generally be well-controlled, randomized, of adequate size, and whenever possible, double-blind. (NCI)
PHASE III TRIAL	   Phase 3. Studies are expanded controlled and uncontrolled trials. They are performed after preliminary evidence suggesting effectiveness of the drug has been obtained, and are intended to gather the additional information about effectiveness and safety that is needed to confirm efficacy and evaluate the overall benefit-risk relationship of the drug and to provide an adequate basis for physician labeling. NOTE: Phase 3 studies usually include from several hundred to several thousand subjects. [After FDA CDER Handbook, ICH E8] (CDISC glossary)
PHASE IIIA TRIAL   A classification typically assigned retrospectively to a Phase III trial upon determination by regulatory authorities of a need for a Phase III B trial. (NCI)
PHASE IIIB TRIAL   A subcategory of Phase III trials done near the time of approval to elicit additional findings. NOTE: Dossier review may continue while associated Phase IIIB trials are conducted. These trials may be required as a condition of regulatory authority approval.
PHASE IV TRIAL	   Phase 4. Postmarketing (Phase 4) studies to delineate additional information about the drug's risks, benefits, and optimal use that may be requested by regulatory authorities in conjunction with marketing approval. NOTE: These studies could include, but would not be limited to, studying different doses or schedules of administration than were used in Phase 2 studies, use of the drug in other patient populations or other stages of the disease, or use of the drug over a longer period of time. [After FDA CDER Handbook, ICH E8] (CDISC glossary)
PHASE V TRIAL	   Postmarketing surveillance is sometimes referred to as Phase V.
PHASE 0 TRIAL	   First-in-human trials, in a small number of subjects, that are conducted before Phase 1 trials and are intended to assess new candidate therapeutic and imaging agents. The study agent is administered at a low dose for a limited time, and there is no therapeutic or diagnostic intent. NOTE: FDA Guidance for Industry, Investigators, and Reviewers: Exploratory IND Studies, January 2006 classifies such studies as Phase 1. NOTE: A Phase 0 study might not include any drug delivery but may be an exploration of human material from a study (e.g., tissue samples or biomarker determinations). [Improving the Quality of Cancer Clinical Trials: Workshop summary-Proceedings of the National Cancer Policy Forum Workshop, improving the Quality of Cancer Clinical Trials (Washington, DC, Oct 2007)] (CDISC glossary)



* TA terms to use: We use an abbreviated term from the CTAUGRS(C160925) code list. If not on the list then type in your own in the TA= parameter
Alzheimer's
Asthma 
Breast Cancer 
Cardiovascular Studies 
Chronic Hepatitis C 
Colorectal Cancer 
COPD 
Diabetic Kidney Disease 
Duchenne Muscular Dystrophy 
Dyslipidemia 
Ebola 
HIV 
Huntington's Disease 
Influenza 
Kidney Transplant 
Major Depressive Disorder 
Malaria 
Multiple Sclerosis 
Pain 
Parkinson's Disease 
Polycystic Kidney Disease (PKD) 
Post Traumatic Stress Disorder 
Prostate Cancer 
QT Studies 
Rheumatoid Arthritis 
Schizophrenia 
Traumatic Brain Injury 
Tuberculosis
Vaccines
Virology
;