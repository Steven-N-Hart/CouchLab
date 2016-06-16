#################################################################################
###             Configure this Script to Run on Your Machine                  ###
###                               Edit Here                                   ###
#################################################################################

# 1. This is just a directory, but needs 2 "\" instead of just 1. 
#     Go to where you want your input files are.
#     You can copy/paste this right from the folder window & add extra backslashes.
setwd("W:\\SEQUENCING\\Margaret\\TNBC Paper\\Files For and From Raymond")


# 2. This is the name of the file.
#     Please follow the designated format [5 columns, Gene, Case_AC, Case_AN, Control_AC, Control_AN]
#     For this test.txt file, I saved it as: "Text (Tab delimited) (*.txt)" <See Step 3.>
inputfile <- "example.csv"


# 3. When you save the file from excel, as a text file it uses a column delimitor, which did you choose?
file_delimitor <- "\t"     # Tab-seperated Fields   (*.txt)
#file_delimitor <- ","    # Comma-seperated Fields (*.csv)


                    ####  How do I run this Code? ####
# If you've opened this code up in Rstudio, just click "Source" in the upper right corner.

# If you are runing this on command line type:  Rscript EasyButton_Calculate_OddsRatios.R
# If you are running this in R GUI, in the window type: 
#     > source('V:/SEQUENCING/Margaret/EasyButton_Calculate_OddsRatios.R', echo=TRUE)

#################################################################################
###              You are Done Editing. Do not Change Code Below               ###
#################################################################################
options(stringsAsFactors=F)
`%nin%` <- Negate(`%in%`) 
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

DataResult=NULL
for(l in 1:nrow(Input)){
  a=Input[l,]$Case_AC
  ab=Input[l,]$Case_AN
  c=Input[l,]$Control_AC
  cd=Input[l,]$Control_AN
  rr=( (a/ab)/(c/cd) )
  se = sqrt((1/a)+(1/c)+(1/ab)+(1/cd))
  cILow=exp(log(rr) - 1.96*se )
  cIHigh=exp(log(rr) + 1.96*se )
  resOR=round(rr,digits = 3)
  resCI=paste(round(cILow,digits = 3),round(cIHigh,digits = 3),sep="-")
  csFreq=round((a/ab)*100,digits = 2)
  nnFreq=round((c/cd)*100,digits = 2)
  DataResult=rbind(DataResult,as.vector(
    c(Input[l,]$Gene,resOR,resCI,a,ab,paste(csFreq,"%",sep=''),c,cd,paste(nnFreq,"%",sep=''))))
}
#ncol(DataResult)
colnames(DataResult)<-c("Gene","RR","95-ConfInt","CaseAC","CaseAN","CaseFreq","ControlAC","ControlAN","ControlFreq")

nom <- sub("^([^.]*).*", "\\1", inputfile)
write.table(DataResult,file=paste(nom,"_Results.tsv",sep=""),quote=F,sep="\t",row.names=F,col.names = T)


