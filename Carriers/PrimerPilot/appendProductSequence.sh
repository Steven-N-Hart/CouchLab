#! /bin/bash
# by Raymond Moore

## just make tabbed file from chunling's excel
# V:\SEQUENCING\60000 project_CARRIERS\HiPLex design\Bioinformatics\BED file_10-6-15.xlsx
#/data5/bsi/epibreast/m087494.couch/Couch/Huge_Breast_VCF/CARRIERS/SubProjects/MayoPrimersSeq_Oct2015/sources/BED_file_10-6-15_sheet1_26genes_SNP.tsv
#/data5/bsi/epibreast/m087494.couch/Couch/Huge_Breast_VCF/CARRIERS/SubProjects/MayoPrimersSeq_Oct2015/sources/BED_file_10-6-15_sheet2_28genes_BRCA.tsv


export GENOME="/data2/bsi/reference/sequence/human/ncbi/37.1/allchr.fa"
INPUT=$1

FN="${INPUT##*/}"
BASEFile="${FN%.*}"

i=0
while read -r line || [[ -n "$line" ]]; do
	if [ $i != 0 ]; then
      loc=`echo -e $line | cut -d' ' -f5`
	  prod=`samtools faidx $GENOME $loc | tr '\n' ' ' | cut -d' ' --complement -f1 | tr -d ' '`
	  #echo $prod
	  echo -e "$line\t$prod" >> "${BASEFile}.seq.tsv"
	else
		echo -e "$line\tProductSeq" > "${BASEFile}.seq.tsv"
    fi	
	i=$i+1
done < "$INPUT"


