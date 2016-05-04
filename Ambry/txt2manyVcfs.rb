require 'pp'

myRefFlat = "/data5/bsi/epibreast/m087494.couch/Couch/Huge_Breast_VCF/Ambry_Project/SubProjects/GenerateVCF/sources/refseq_hg19_first_exome_only.bed"

def getVCFheader
	return "##fileformat=VCFv4.1\n##FILTER=<ID=LOW_VQSLOD,Description=\"VQSLOD < 0.0\">\n##FILTER=<ID=LowQual,Description=\"Low quality\">\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n##contig=<ID=chr1,length=249250621>\n##contig=<ID=chr2,length=243199373>\n##contig=<ID=chr3,length=198022430>\n##contig=<ID=chr4,length=191154276>\n##contig=<ID=chr5,length=180915260>\n##contig=<ID=chr6,length=171115067>\n##contig=<ID=chr7,length=159138663>\n##contig=<ID=chr8,length=146364022>\n##contig=<ID=chr9,length=141213431>\n##contig=<ID=chr10,length=135534747>\n##contig=<ID=chr11,length=135006516>\n##contig=<ID=chr12,length=133851895>\n##contig=<ID=chr13,length=115169878>\n##contig=<ID=chr14,length=107349540>\n##contig=<ID=chr15,length=102531392>\n##contig=<ID=chr16,length=90354753>\n##contig=<ID=chr17,length=81195210>\n##contig=<ID=chr18,length=78077248>\n##contig=<ID=chr19,length=59128983>\n##contig=<ID=chr20,length=63025520>\n##contig=<ID=chr21,length=48129895>\n##contig=<ID=chr22,length=51304566>\n##contig=<ID=chrX,length=155270560>\n##contig=<ID=chrY,length=59373566>\n##contig=<ID=chrM,length=16569>\n##reference=file:///data2/bsi/reference/sequence/human/ncbi/hg19/allchr.fa\n##INFO=<ID=Ambry_Zygosity,Number=.,Type=String,Description=\"Custom Annotation\",Source=\"Ambry\">\n##INFO=<ID=Ambry_Mutation,Number=.,Type=String,Description=\"Custom Annotation\",Source=\"Ambry\">\n##INFO=<ID=Ambry_Gene,Number=.,Type=String,Description=\"Custom Annotation\",Source=\"Ambry\">\n##INFO=<ID=Ambry_HGVSc,Number=.,Type=String,Description=\"Custom Annotation\",Source=\"Ambry\">\n##INFO=<ID=Ambry_HGVSp,Number=.,Type=String,Description=\"Custom Annotation\",Source=\"Ambry\">\n##INFO=<ID=Ambry_MutanalyzerInput,Number=.,Type=String,Description=\"Custom Annotation\",Source=\"mutalyzer.nl\">\n##source=ManuallyCreated"
end


GENOME="/data2/bsi/reference/sequence/human/ncbi/37.1/allchr.fa"
lastSampleName="x"
out = File.open("x.tmp","w")
header = ["#CHROM","POS","ID","REF","ALT","QUAL","FILTER","INFO","FORMAT"]

refFlatHash=Hash.new
File.readlines(myRefFlat).each do |ln|
	rr=ln.chomp.split(/\t/)
	#refFlatHash[rr[3]]=rr ## don't just collect the first exon, derive the variant
	pos = rr[1].to_i + 3
	elevenDelPos = pos + 11
	refbases = `samtools faidx #{GENOME} #{rr[0]}:#{pos}-#{elevenDelPos}`.split(/\n/)[1]
	refFlatHash[ rr[3] ] = [ rr[0],pos,refbases,refbases[0],rr[3] ]
end

outputDirName='IntermediateVCFs'
if !Dir.exists?(outputDirName)
	Dir.mkdir outputDirName
end

### NEED TO ADD ADDITIONAL EXCEPTION (I found later) - check for spaces in variant definition!! SNPs in CIS
## NM_000249.3:c.-27C>A + c.85G>T - short distance, able to  pull ref seq and make 2 changes
## NM_003000.2:c.194T>A + c.200+3G>C - too long, just split into 2 SNPs


File.readlines(ARGV[0]).each_with_index do |ln, idx|
	rr = ln.split(/\t/)
	vcfline = []
	infoLine = []
	
	if rr[0] != lastSampleName
		if !out.closed?
			out.close
		end
		out = File.open("#{outputDirName}/#{rr[0]}.vcf","w")
		out.puts getVCFheader
		out.puts [header,rr[0]].flatten.join("\t")
		lastSampleName = rr[0]
	end
	
	mutResults = rr[10].chomp!
	### IF COMMON SNP - L>L
	if rr[10] =~ /(del|dup|ins)/
		### Get the Chr
		nc = mutResults.split(/:/)[0].split('.')[0].sub(/^NC_/,'').to_i
		vcfline[0] = "chr#{nc}"
		
		if mutResults =~ /delins/
			#pp ["DEL-INS", mutResults]
			ps = mutResults.split(/:/)[1].split('.')[1].split(/delins/)[0]
			if ps =~ /_/
				psExact = ps.split(/_/)
			else
				psExact = [ps,ps]
			end
			psExact.map!{|i| i.to_i}
			psExact[0] = psExact[0] - 1
			refbases = `samtools faidx #{GENOME} chr#{nc}:#{psExact[0]}-#{psExact[1]}`.split(/\n/)[1]
			alts = mutResults.split(/:/)[1].split('.')[1].split(/delins/)[1]
			vcfline[1] = psExact[0]
			vcfline[3] = refbases
			vcfline[4] = "#{refbases[0]}#{alts}"	
		elsif mutResults =~ /dup/
			ps  = mutResults.split(/:/)[1].split('.')[1].sub(/dup$/,'')
			### One base DUP vs many
			if ps =~ /_/
				psExact = ps.split(/_/)
			else
				psExact = [ps,ps]
			end
			dupbases = `samtools faidx #{GENOME} chr#{nc}:#{psExact[0]}-#{psExact[1]}`.split(/\n/)[1]
			pos = psExact[0].to_i - 1 
			refBase = `samtools faidx #{GENOME} chr#{nc}:#{pos}-#{pos}`.split(/\n/)[1]
			vcfline[1] = pos
			vcfline[3] = refBase
			vcfline[4] = "#{refBase}#{dupbases}"
		
		elsif mutResults =~ /del/
			ps = mutResults.split(/:/)[1].split('.')[1]
			### One base DEL vs many
			if ps =~ /_/
				psExact = ps.split(/del/)[0].split(/_/)
			else
				ptmp = ps.split(/\D/)[0]
				psExact = [ptmp,ptmp]
			end
			prePs = psExact[0].to_i - 1 
			refbases = `samtools faidx #{GENOME} chr#{nc}:#{prePs}-#{psExact[1]}`.split(/\n/)[1]
			vcfline[1] = prePs
			vcfline[3] = refbases
			vcfline[4] = refbases[0]	
		elsif mutResults =~ /ins/
			ps = mutResults.split(/:/)[1].split('.')[1]
			if ps =~ /_/
				psExact = ps.split(/ins/)[0].split(/_/)[0].to_i - 1
			else
				psExact = ps.split(/\D/)[0].to_i - 1
			end
			
			refb = `samtools faidx #{GENOME} chr#{nc}:#{psExact}-#{psExact}`.split(/\n/)[1]
			alts = ps.split(/ins/)[1]
			vcfline[1] = psExact
			vcfline[3] = refb
			vcfline[4] = "#{refb}#{alts}"
			#pp ["insert", ps, psExact, refb, alts, mutResults]
		else
			pp ["UNHANDLED CASE!!", mutResults,rr[5]]
			exit
		end

	
	elsif rr[10] =~ /\w>\w/
		### Get the Chr
		nc = mutResults.split(/:/)[0].split('.')[0].sub(/^NC_/,'').to_i
		vcfline[0] = "chr#{nc}"
		### Get the Pos
		ps = mutResults.split(/:/)[1].split('.')[1].split(/\D/)[0]
		vcfline[1] = ps
		### Get Ref & Alt
		ra = mutResults.split(/:/)[1].split('.')[1].split(/\d/).last.split(/>/)
		vcfline[3] = ra[0]
		vcfline[4] = ra[1]
		### CHECK AGAINST GENOME
		#samtools faidx $GENOME chr7:6026706-6026709
		#pp [ra, mutResults]
	else
		if !refFlatHash.has_key?(rr[4])
			puts "NO REFERENCE EXON FOR: #{rr[4]}"
			exit
		end
		vcfline[0] = refFlatHash[rr[4]][0]
		vcfline[1] = refFlatHash[rr[4]][1] # position
		vcfline[3] = refFlatHash[rr[4]][2] # ref bases
		vcfline[4] = refFlatHash[rr[4]][3] # 10bp deletion
		#puts "NON-MATCH = #{rr[6]}"
		#pp [rr[4],rr[5],rr[8],rr[9],rr[10]]
	end
	
	infoLine.push("Ambry_Zygosity=#{rr[1]}")
	infoLine.push("Ambry_Mutation=#{rr[2]}")
	infoLine.push("Ambry_Gene=#{rr[4]}")
	infoLine.push("Ambry_HGVSc=#{rr[5]}")
	if rr[6] != ""
		infoLine.push("Ambry_HGVSp=#{rr[6]}")
	end
	infoLine.push("Ambry_MutanalyzerInput=#{rr[7]}")
	
	vcfline[2] = '.'
	vcfline[5] = '100'
	vcfline[6] = 'PASS'
	vcfline[7] = infoLine.join(';')
	vcfline[8] = 'GT'

	if rr[1] == "confirmed_HOMO"
		vcfline[9] = '1/1'
	else
		vcfline[9] = '0/1'
	end
	
	#out.puts "chr\t0\t.\tZ\tz\t100\tPASS\tSAMP=#{rr[0]}\tGT\t0/1"
	out.puts vcfline.join("\t")
	
	#break if idx >= 2400
end

File.delete("x.tmp")


