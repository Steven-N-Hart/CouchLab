options(stringsAsFactors=F)
setwd("C:\\Users\\m088378\\Desktop") ## May need to edit Mount
list.files()


IN<-read.csv(file="W:\\SEQUENCING\\Ambry\ 110000\ tests\\Clinical Data DEIDENTIFIIED.csv",header=T, na.strings = '.')
#IN<-read.csv(file="ambry_new_samples.txt",header=T, sep="\t",na.strings = '.')
TBL<-read.csv(file="C:\\Users\\m088378\\Documents\\CouchLab_Github\\Ambry\\AmbryTestPanelBreakdown.txt",header=T, sep="\t",na.strings = '.')
names(TBL)

for(g in TBL$Gene){
  print(g)
  IN[,g]<-0
}

names(IN)
inTestNames <- sort(unique(unlist(IN$Test.Name.Condensed)))
tblTestNames <- sort(names(TBL))
setdiff(tblTestNames,inTestNames)
setdiff(inTestNames,tblTestNames)

for(i in 1:nrow(IN)){
#for(i in 1:10){
  tsNom <- gsub(" ", ".", IN[i,]$Test.Name)
  #tsNom <- "Custom.Panel.-.BRCAplus"
  #tsNom <- "CancerNext"
  if( grepl('Custom.Panel', tsNom) ){
    next
  }
  print(tsNom)
  idx<-which( !is.na(TBL[,tsNom]))
  gs<-TBL[idx,]$Gene
  IN[i,gs]<-1
  
  if(IN[i,]$Pre.Post.BRCA == "PreBRCA" ){
    IN[i,c("BRCA1","BRCA2")]<-0
  }
  if(IN[i,]$Pre.Post.NF1...RAD51D == "PreNF1" ){
    IN[i,c("NF1","RAD51D","CDK4","CDKN2A")]<-0
  }
  if(IN[i,]$Pre.Post.STK11.removal == "STK11 Removed" ){
    IN[i,c("STK11")]<-0
  }
  if(IN[i,]$Pre.Post.STK11.removal == "STK11 Included" ){
    IN[i,c("STK11")]<-1
  }
  if(IN[i,]$Pre.Post.GREM1..POLD1..POLE..etc == "PreGREM1" ){
    if(IN[i,]$Test.Name == "RenalNext" | IN[i,]$Test.Name == "CancerNext Expanded" ){
      IN[i, c("BAP1")]<-0
    }
    if(IN[i,]$Test.Name == "ColoNext" | IN[i,]$Test.Name == "CancerNext" | IN[i,]$Test.Name == "CancerNext Expanded" ){
      IN[i, c("POLD1","POLE","GREM1")]<-0
    }
    if(IN[i,]$Test.Name == "OvaNext" | IN[i,]$Test.Name == "CancerNext" | IN[i,]$Test.Name == "CancerNext Expanded" ){
      IN[i, c("SMARCA4")]<-0
    }
    if(IN[i,]$Test.Name == "PGLNext" | IN[i,]$Test.Name == "CancerNext Expanded" ){
      IN[i, c("MEN1")]<-0
    }
    if(IN[i,]$Test.Name == "PGLNext" ){
      IN[i, c("FH")]<-0
    }
    
  }
  if(IN[i,]$Pre.Post.PALB2 == "PrePALB2" ){
    IN[i,c("PALB2")]<-0
  }
}


nrow(IN)
INp1 <- IN[1:62000,]
write.table(INp1,file="ambry_new_samples.output01.txt",row.names=F,sep="\t")
INp2 <- IN[62001:122578,]
write.table(INp2,file="ambry_new_samples.output02.txt",row.names=F,sep="\t")

# plus_GenePanelsListedOut


