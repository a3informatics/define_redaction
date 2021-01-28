library(dplyr)
library(xml2)
library(stringr)
library(openssl)

#Finding the items to replace
#Redact study name and description
remove_study_details <- function(file_in,file_out,ph,ta){
  define<-read_xml(file_in)
  studyname<-xml_text(xml_find_all(define, ".//d1:StudyName"))
  StudyDescription<-xml_text(xml_find_all(define, ".//d1:StudyDescription"))
  studyOID<-studyOID<-xml_attr(xml_find_all(define, ".//d1:Study"), "OID", xml_ns(define))
  #Update the define with items found above
  define_redact<-read_xml(gsub(studyname,'REDACTED STUDY',define))
  define_redact<-read_xml(gsub(studyOID,'REDACTED STUDY',define_redact))
  define_redact<-read_xml(gsub(StudyDescription,paste('A redacted study description.',paste('Phase:',ph,', TA:',ta,sep="")), define_redact))
  write_xml(define_redact,file_out)
}

remove_comments <- function(file_in,file_out){
  define<-read_xml(file_in)
  supp<-xml_attr(xml_find_all(define, "//def:CommentDef"), "OID", xml_ns(define))
  if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      OID<-noquote(gsub(" ","",paste('\"',supp[k],'\"')))
      define_redact<-read_xml(file_in)
      del<-xml_find_all(define_redact, paste('//def:CommentDef[@OID =',OID,']'))
      print(del)
      xml_remove(del)
      write_xml(define_redact,file_out)
    }}
    
  else {
    print("No comments found in define")
    }
}

redact_text<-function(redact_txt,file_in,file_out){
  for (k in 1:length(redact_txt)) {
    define<-read_xml(file_in)
    define_redact<-read_xml(gsub(redact_txt[k],'Redacted text',define))
    write_xml(define_redact,file_out)
  }}

remove_extended_values <- function(file_in,file_out){
  define<-read_xml(file_in)
  supp<-xml_find_all(define, '//d1:CodeListItem[@def:ExtendedValue=\"Yes\"]')
  if (length(supp) > 0 )
  {
      define_redact<-read_xml(file_in)
      del<-xml_find_all(define_redact, '//d1:CodeListItem[@def:ExtendedValue=\"Yes\"]')
      print(del)
      xml_remove(del)
      
      # Removing the extended values from the check values in any whereclause
      ext_val<-xml_attr(xml_find_all(define, '//d1:CodeListItem[@def:ExtendedValue=\"Yes\"]'),"CodedValue", xml_ns(define))
      for (k in 1:length(ext_val)) {
        chk_val<-xml_text(xml_find_all(define, "//d1:CheckValue"))
        check_val_row<-xml_find_all(define, "//d1:CheckValue")
         for (j in 1:length(chk_val)){
             if (chk_val[j] == ext_val[k]){
               print(paste(check_val_row[j],"being replace with redacted text"))
              define_redact<-read_xml(gsub(check_val_row[j],'<CheckValue>Redacted text</CheckValue>',define_redact)) 
             }
           }
      write_xml(define_redact,file_out)      
    }
  }
  else {
    print("No extended values found in define")
  }
}


 
remove_domain <- function(domain,file_in,file_out){
  define<-read_xml(file_in)
  supp<-str_subset(xml_attr(xml_find_all(define, "//d1:ItemGroupDef"), "OID", xml_ns(define)), domain)
  print(supp)
  if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      OID<-noquote(gsub(" ","",paste('\"',supp[k],'\"')))
      define_redact<-read_xml(file_in)
      del<-xml_find_all(define_redact, paste('//d1:ItemGroupDef[@OID =',OID,']'))
      print(paste('Delete ItemGroup:',del))
      xml_remove(del)
      write_xml(define_redact,file_out)
    }}
  else {
    print(paste("Domain:",domain,"not found in define.xml"))
  }
  
  supp<-str_subset(xml_attr(xml_find_all(define, "//d1:ItemDef"), "OID", xml_ns(define)), gsub(" ","",(paste('IT.',noquote(domain)))))
  print(gsub(" ","",(paste('IT.',noquote(domain)))))
  print(supp)
  if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      OID<-noquote(gsub(" ","",paste('\"',supp[k],'\"')))
      define_redact<-read_xml(file_out)
      del<-xml_find_all(define_redact, paste('//d1:ItemDef[@OID =',OID,']'))
      print(paste('Delete ItemDef:',del))
      xml_remove(del)
      write_xml(define_redact,file_out)
    }}
  
  supp<-str_subset(xml_attr(xml_find_all(define, "//d1:MethodDef"), "OID", xml_ns(define)), gsub(" ","",(paste('MT.',noquote(domain)))))
  print(supp)
  if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      OID<-noquote(gsub(" ","",paste('\"',supp[k],'\"')))
      define_redact<-read_xml(file_out)
      del<-xml_find_all(define_redact, paste('//d1:MethodDef[@OID =',OID,']'))
      print(paste('Delete MethodDef:',del))
      xml_remove(del)
      write_xml(define_redact,file_out)
    }}
  
  supp<-str_subset(xml_attr(xml_find_all(define, "//def:ValueListRef"), "ValueListOID", xml_ns(define)), gsub(" ","",(paste('VL.',noquote(domain)))))
  print(supp)
  if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      OID<-noquote(gsub(" ","",paste('\"',supp[k],'\"')))
      define_redact<-read_xml(file_out)
      del<-xml_find_all(define_redact, paste('//def:ValueListRef[@ValueListOID =',OID,']'))
      print(paste('Delete ValueListRef:',del))
      xml_remove(del)
      write_xml(define_redact,file_out)
    }}
  
  supp<-str_subset(xml_attr(xml_find_all(define, "//def:ValueListDef"), "OID", xml_ns(define)), gsub(" ","",(paste('VL.',noquote(domain)))))
  print(supp)
    if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      OID<-noquote(gsub(" ","",paste('\"',supp[k],'\"')))
      define_redact<-read_xml(file_out)
      del<-xml_find_all(define_redact, paste('//def:ValueListDef[@OID =',OID,']'))
      print(paste('Delete ValueListDef:',del))
      xml_remove(del)
      write_xml(define_redact,file_out)
    }}
}

delete_CL <- function(CL,file_in,file_out){
  define<-read_xml(file_in)
  supp<-str_subset(xml_attr(xml_find_all(define, "//d1:CodeList"), "OID", xml_ns(define)), gsub(" ","",(paste('CL.',noquote(CL)))))
  print(supp)
  if (length(supp) > 0 )
  {
    for (k in 1:length(supp)) {
      if (supp[k] == gsub(" ","",(paste('CL.',noquote(CL))))){
      OID<-noquote(gsub(" ","",paste("'",supp[k],"'")))
      define_redact<-read_xml(file_in)
      del<-xml_find_all(define_redact, paste('//d1:CodeList[@OID =',OID,']'))
      print(paste('Delete CodeList:',del))
      xml_remove(del)
      write_xml(define_redact,file_out)
      }}}
  else {
    print(paste("Codelist:",CL,"not found in define.xml"))
  }

supp<-str_subset(xml_attr(xml_find_all(define, "//d1:CodeListRef"), "CodeListOID", xml_ns(define)), gsub(" ","",(paste('CL.',noquote(CL)))))
if (length(supp) > 0 )
{
  for (k in 1:length(supp)) {
    if (supp[k] == gsub(" ","",(paste('CL.',noquote(CL))))){
    OID<-noquote(gsub(" ","",paste("'",supp[k],"'")))
    define_redact<-read_xml(file_in)
    del<-xml_find_all(define_redact, paste('//d1:CodeListRef[@CodeListOID =',OID,']'))
    print(paste('Delete CodeListRef:',del))
    xml_remove(del)
    write_xml(define_redact,file_out)
  }}}

}

redact_define <- function(file_in, company_name="ACME", phase="NA", TA="NA", remove_comments="N", remove_extended_cl_val="N", remove_domains=NULL, remove_CL=NULL, redact_text=NULL){

  #HASH convert company name. to be used in output filename.
  name <-paste("define_",md5(company_name),"_redact.xml", sep="")
  #Initially reads in the define - after study details have been removed the redacted define (name) is processed as input below
  remove_study_details(file_in,name,phase,TA)
  #Remove comments in all domains.
  if (remove_comments == 'Y') {
  remove_comments(name,name)
  }
  
  #Remove extended values in all code lists.
  if (remove_extended_cl_val == 'Y') {
    remove_extended_values(name,name)
  }
  
  if (!is.null(redact_text)) {
      #Remove any test in the define
      redact_text(redact_text,name,name)
  }
  
  if (!is.null(remove_domains)) {
     #Remove a whole domain - call this for each domain you need to delete
    for (k in 1:length(remove_domains)){
     remove_domain(remove_domains[k],name,name)
    }}
  
  if (!is.null(remove_CL)) {
    #Remove a whole domain - call this for each domain you need to delete
    for (k in 1:length(remove_CL)){
      delete_CL(remove_CL[k],name,name)
    }}
  
  print(paste("Define file has been redacted and out in:",name))
}