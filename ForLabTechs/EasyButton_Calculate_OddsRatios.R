options(stringsAsFactors=F)
`%nin%` <- Negate(`%in%`) 

#################################################################################
###             Configure this Script to Run on Your Machine                  ###
###                               Edit Here                                   ###
#################################################################################

# 1. This is just a directory, but needs 2 "\" instead of just 1. 
#     Go to where you want your input files are.
#     You can copy/paste this right from the folder window & add extra backslashes.
setwd("W:\\SEQUENCING\\Ambry Updated Cohort 85000_4-8-16\\Ambry data analysis\\breast cancer")


# 2. This is the name of the file.
#     Please follow the designated format [5 columns, Gene, Case_AC, Case_AN, Control_AC, Control_AN]
#     For this test.txt file, I saved it as: "Text (Tab delimited) (*.txt)" <See Step 3.>
inputfile <- "Ambry_ExAC_BAD.txt"


# 3. When you save the file from excel, as a text file it uses a column delimitor, which did you choose?
file_delimitor <- "\t"     # Tab-seperated Fields   (*.txt)
# file_delimitor <- ","    # Comma-seperated Fields (*.csv)


                    ####  How do I run this Code? ####
# If you've opened this code up in Rstudio, just click "Source" in the upper right corner.

# If you are runing this on command line type:  Rscript EasyButton_Calculate_OddsRatios.R
# If you are running this in R GUI, in the window type: 
#     > source('V:/SEQUENCING/Margaret/EasyButton_Calculate_OddsRatios.R', echo=TRUE)

#################################################################################
###              You are Done Editing. Do not Change Code Below               ###
#################################################################################


Input<-read.csv(file=inputfile,header=T, sep=file_delimitor,na.strings = '.')

#Check input file format
expected_names <- c("Gene", "Case_AC", "Case_AN", "Control_AC", "Control_AN")
missing_names <- expected_names %nin% names(Input)
for( n in 1:length(missing_names) ){
  if(missing_names[n]){stop(paste("Input File Missing Column:", expected_names[n]))}  
}

# Check for non-numeric
is_num <- is.numeric(Input$Case_AC)
if(!is_num){stop("Case AC Column Does Not Contain Only Numbers!")}
is_num <- is.numeric(Input$Case_AN)
if(!is_num){stop("Case AN Column Does Not Contain Only Numbers!")}
is_num <- is.numeric(Input$Control_AC)
if(!is_num){stop("Control AC Column Does Not Contain Only Numbers!")}
is_num <- is.numeric(Input$Control_AN)
if(!is_num){stop("Control AN Column Does Not Contain Only Numbers!")}
# Check for Zeros in AN
has_zero <- any(Input$Case_AN == 0)
if(has_zero){stop("Case AN Column Contains a Zero! Must Be Non-Zero Only!")}
has_zero <- any(Input$Control_AN == 0)
if(has_zero){stop("Control AN Column Contains a Zero! Must Be Non-Zero Only!")}


#######################################
###        Basic Functions          ###
remain<-function(xAC,xAN){
  r<-(xAN-xAC);
  if(r < 0){r<-1}
  return(r)
}

DataResult=NULL
for(l in 1:nrow(Input)){
  csAC <- Input[l,]$Case_AC
  nnAC <- Input[l,]$Control_AC
  mat=matrix(c(csAC,remain(csAC,Input[l,]$Case_AN), nnAC, remain(nnAC,Input[l,]$Control_AN)), nrow = 2)
  res=fisher.test(mat)
  resOR=round(res$estimate,digits = 3)
  resPval=sprintf("%.3g", res$p.val)
  resCI=paste(round(res$conf.int[1],digits = 3),round(res$conf.int[2],digits = 3),sep="-")
  csFreq=round((csAC/Input[l,]$Case_AN)*100,digits = 2)
  nnFreq=round((nnAC/Input[l,]$Control_AN)*100,digits = 2)
  DataResult=rbind(DataResult,as.vector(
    c(Input[l,]$Gene,resOR,resPval,resCI,csAC,Input[l,]$Case_AN,
      paste(csFreq,"%",sep=''),nnAC,Input[l,]$Control_AN,paste(nnFreq,"%",sep=''))))
}
#ncol(DataResult)
colnames(DataResult)<-c("Gene","OR","p-value","95-ConfInt","CaseAC","CaseAN","CaseFreq","ControlAC","ControlAN","ControlFreq")

nom <- sub("^([^.]*).*", "\\1", inputfile)
write.table(DataResult,file=paste(nom,"_Results.tsv",sep=""),quote=F,sep="\t",row.names=F,col.names = T)


