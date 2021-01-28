#set working directory - edit to fit your own wd
setwd("~/S-cubed Aps/BC Miner - General/RedactScripts/R/")
#Do not delete below
source("RedactDefineFunctions.R")


#Redact all study details
#studyname will be set to: REDACTED STUDY
#study description will be set to: A redacted study description

# 1. Specify the name of the input define.xml file. If not in folder set in setwd above then put in full path.
# 2. Specify company name - will be used in the name of the redacted defie.xml as a hash value, e.g. define_3fbeb6a5a3e2f60d2a9c015a6f527a08_redact.xml
# 3. Specify phase of the study  - for define.xml miner tool to do statistics. 
#    Will be added to redacted study description: <StudyDescription>A redacted study description. Phase:3, TA:Asthma</StudyDescription>
# 4. Specify Therapeutic Area of the study  - for define.xml miner tool to do statistics. See terminology at the bottom of this file.
# 5. Specify if all comments are to be removed, default is N.
# 6. Specify if extended code list values should be removed. Default is N
# 7. Specify the list of domains to remove, if any. Default is NULL.
# 8. Specify the list of code lists to remove, if any. Defaults is NULL.
# 9. Specify if any other text must be redacted. Use quotes if text contains space;

#example of no comments are to be removed and no domains. Only study ID and study description will be removed.
#redact_define("define.xml", company_name="ACME", phase="32", TA="Asthma")
                              
redact_define("define-sdtm-3.1.2.xml", 
              company_name="CDISC", 
              phase="3", 
              TA="Alzheimer's", 
              remove_comments="Y", 
              remove_extended_cl_val="Y", 
              remove_domains=c("IE","FA"),
              remove_CL=c("IETEST","IETESTCD"),
              redact_text=c("Miracle Drug","WONDER"))

# TA terms to use: We use an abbreviated term from the CTAUGRS(C160925) code list. If not on the list then type in your own in the TA= parameter
# Alzheimer's
# Asthma 
# Breast Cancer 
# Cardiovascular Studies 
# Chronic Hepatitis C 
# Colorectal Cancer 
# COPD 
# Diabetic Kidney Disease 
# Duchenne Muscular Dystrophy 
# Dyslipidemia 
# Ebola 
# HIV 
# Huntington's Disease 
# Influenza 
# Kidney Transplant 
# Major Depressive Disorder 
# Malaria 
# Multiple Sclerosis 
# Pain 
# Parkinson's Disease 
# Polycystic Kidney Disease (PKD) 
# Post Traumatic Stress Disorder 
# Prostate Cancer 
# QT Studies 
# Rheumatoid Arthritis 
# Schizophrenia 
# Traumatic Brain Injury 
# Tuberculosis
# Vaccines
# Virology
