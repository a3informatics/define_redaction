* Extracts Value Level Metadata from SDTM SAS datasets
* to be used for creation of Biomedical Concepts.
* ONLY looks a datasets that includes a --TESTCD

* Responsible Programmer: Kirsten Walther Langendorf
* Date: 19-Mar-2021
;

*******CHANGE*******: file reference to the macro to fit your location;
%include "S:\Glandon\BCMiner\VLMdata\Data2VLM_macro.sas";
*******SPECIFY*******: the location of the SAS datasets;
libname indata  "S:\Glandon\CDISC Pilot\tabulations\datasets";

*******INPUT PARAMETERS********
* 1. indat - the libanme assigned above;
* 2. TA - Therapeutic Area - see list below. If not in the list put in the relevant text;
* 3. phase - phase of trial - see list below;
* 4. out - the location and name of the excel output;
%VLMD_data(indata, TA=%bquote(Alzheimer's), phase=PHASE III TRIAL, out=S:\Glandon\BCMiner\VLMdata\VLMD.xlsx);

* NOTE:
* The WORK directory will contain two datasets: 
* - QUALIFIER which are the qualifers being defined (read in as data lines) in the beginning of the macro. It is qualifiers taken from SDTM model 1.8.
* - VLMD which is the dataset being written to the excel file. User can change name of the excel file written out using the out=parameter above.;
*
* IF --ORRES is missing for a value of a --TESTCD then a warning is put in the log:
* WARNING: No non-missing data found for table=QS column=QSORRES value=NPITM10
*
* A WHERECLAUSE column is constructed that will combine all non-missing qualifiers into a whereclause
* Examples:
* (VSTESTCD EQ "SYSBP") AND (VSPOS EQ "SUPINE")
* (VSTESTCD EQ "TEMP") AND (VSLOC EQ "ORAL")
*

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