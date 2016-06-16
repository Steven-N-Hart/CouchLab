### NEED TO correctly generate the domain catalog
library(jsonlite)
library(mgcv)
library(XML)
options(stringsAsFactors=F)

outPath <- file.path("C:","Users","m088378","Desktop","ambryDomainsCatalog2.tsv")

#Function for additional formatting:
get.cds<-function(gene.name,gene.dat){
  #Pull CDS regions
  gene.cds<-gene.anno[gene.anno[,3]=="CDS",]
  if(dim(gene.cds)[1]==0){return (0)}
  

  TMP<-merge(pos.mat,gene.dat,all.x=TRUE)
  TMP$CHROM<-unique(na.omit(gene.dat$CHROM))
  return(TMP)
}


### on RCF-Data2
illuminaRef <- file.path("U:","bsi","reference","tophat","genes_Illumina_iGenomes.gtf")
gannot<-read.table(illuminaRef, header=FALSE, sep='\t')
genenm <- strsplit(gannot[,'V9'],split=';')
gannot[,'TranscriptID'] <- gsub(' transcript_id ','',unlist(lapply(genenm,function(x) { return(x[2])})))
gannot[,'GeneID'] <- gsub('gene_id ','',unlist(lapply(genenm,function(x) { return(x[1])})))
gannot[,'GeneID'] <- ifelse(gannot[,'GeneID'] %in% c('FAM45B','MIR1256','TTL'), paste(gannot[,'V1'],gannot[,'GeneID'],sep='-'), gannot[,'GeneID'])
gannot[,'GeneID'] <- ifelse(gannot[,'GeneID'] %in% c('BK250D10.8','HGC6.3','CN5H6.4','RP11-165H20.1','RP1-177G6.2'),substring(gannot[,'GeneID'],1,regexpr('\\.',gannot[,'GeneID'])-1),gannot[,'GeneID'])
gannot<-gannot[-(grep("_",gannot$V1)),]


### File Format:
## uni_acc|protein_id|domain_name|Gene|type|start|stop|description|ref|ImportantCancerPredisposition
##
couchHandPicked <- file.path("W:","SEQUENCING","DomainAnnotations","InputSources","round2Domains_inputRscript.txt")
desiredDomains<-read.csv(couchHandPicked,header=T,sep="\t")
desiredDomains$ref=NULL
names(desiredDomains)

justCDS<-gannot[which(gannot$V3 == "CDS"),]
## Original
#desiredTranscripts<-c("NM_000051","NM_000465","NM_007294","NM_000059","NM_032043","NM_004360",
#                      "NM_007194","NM_000249","NM_005591","NM_000251","NM_000179","NM_001128425",
#                      "NM_002485","NM_001042492","NM_024675","NM_000535","NM_000314","NM_005732",
#                      "NM_058216","NM_002878","NM_000455","NM_000546")
desiredTranscripts<-c("NM_000135","NM_000136","NM_001114636","NM_001128425","NM_004629","NM_005431",
                      "NM_020937","NM_021922","NM_022725","NM_024596","NM_032941")


ambryDomains<-justCDS[which(justCDS$TranscriptID %in% desiredTranscripts),]
colnames(ambryDomains) <- c("Chr","Source","Feature","Pos1","Pos2","Score","Strand","Frame","Desc","TranscriptID","GeneID")
ambryDomains$cds.size<-ambryDomains$Pos2-ambryDomains$Pos1+1






#### FOR LOOP ###
myGenesList <- sort(unique(unlist(desiredDomains$Gene)))
for(kGENE in myGenesList){
  print(kGENE)
  gene.domains<-unique(desiredDomains[which(desiredDomains$Gene==kGENE),])
  gene.anno<-unique(ambryDomains[which(ambryDomains$GeneID==kGENE),])
  aa.size<-sum(gene.anno$cds.size)/3
  ### always pos1 -> pos2 because it's the refence genome positions
  genomic.pos<-c()
  for(i in 1:nrow(gene.anno)){
    genomic.pos <- c(genomic.pos, seq(gene.anno$Pos1[i],gene.anno$Pos2[i]))
  }
  
  cds.pos<-1:length(genomic.pos)
  aa.pos<-rep(c(1:aa.size), each=3)
  
  if(gene.anno$Strand[1]=="+"){
    pos.mat<-cbind(genomic.pos,cds.pos,aa.pos)
  } else{
    pos.mat<-cbind(genomic.pos,rev(cds.pos),rev(aa.pos))
  }
  colnames(pos.mat)<-c("POS","CDS_Position","AA_Position")
  myPositions<-as.data.frame(pos.mat)
  
  
  
  #names(gene.domains)
  
  #j=1
  
  for(j in 1:nrow(gene.domains)){
    test<-data.frame()
    
    ## get this domian's extreme boundaries
    firstAA<-gene.domains$start[j]
    lastAA<-gene.domains$stop[j]
    ## get all genomic breakpoints, index of previous exon boundary
    tmp<-myPositions[which(firstAA <= myPositions$AA_Position & myPositions$AA_Position <= lastAA),]
    preJumpsIdx<-which(diff(tmp$POS) != 1)
  
    allStarts<-c(1,preJumpsIdx+1)
    allEnds<-c(preJumpsIdx,length(tmp$POS))
    
    
    test <- cbind(tmp$POS[allStarts], tmp$POS[allEnds])
    tmpD <- gene.domains[j,]
    
    m1 <- merge(test,tmpD,all=T)
    m1$Chr<-gene.anno$Chr[1]
    m1$RefSeqtranscript<-gene.anno$TranscriptID[1]
    m1$strand<-gene.anno$Strand[1]
    
    write.table(m1, outPath, append=TRUE, sep="\t", col.names=F, row.names=F)
    
  }
}

