require 'pp'
require 'date'
### Usage: ruby genomeGPS_2_redcap.rb -d <raw database.csv> -i <input dir>
#### Help Statement ####
if ARGV[0]=='-h' || ARGV[0]=='--help'
  usageStr="Usage: ruby  This script will parse the Couch RedCap file, & create an uploadable update file. This script accepts the GenomeGPS Config directory, and looks for run & sample info.\n\n"
  usageStr+="\t-d <redcap file new db .csv> [required]\n"
  usageStr+="\t-i <GenomeGPS config dir> [required]\n"
  usageStr+="\t-w <Y/n> (Optional) Print warning?\n"
  puts usageStr+"\n"
  exit 0
end
opt = Hash[*ARGV]
warningsOn=false

#### Check Input Params ####
if !opt.has_key?('-d')
  STDERR.puts "Missing RedCap File!"
  exit 1
end
dbFile=opt['-d']
if !opt.has_key?('-i')
  STDERR.puts "Missing GenomeGPS Directory!"
  exit 1
end
if !File.exist?("#{opt['-i']}/run_info.txt")
	STDERR.puts "This Directory Is Missing its run_info.txt file!"
	exit 1
end
runInfo = "#{opt['-i']}/run_info.txt"
if !File.exist?("#{opt['-i']}/sample_info.txt")
	STDERR.puts "This Directory Is Missing its sample_info.txt file!"
	exit 1
end
sampleInfo = "#{opt['-i']}/sample_info.txt"
if !File.exist?("#{opt['-i']}/tool_info.txt")
	STDERR.puts "This Directory Is Missing its tool_info.txt file!"
	exit 1
end
toolInfo = "#{opt['-i']}/tool_info.txt"
if opt.has_key?('-w')
	if opt['-w'] == "Y"
		warningsOn = true
		puts "Turn warnings \"ON\""
	end
end

#### Get Executer Info ####
nom = `whoami`.chomp!
allNom = `finger #{nom}`
allData = allNom.split(/\n/).select{|a| a =~ /Name\:/}.first.split(/\t/).select{|a| a =~ /Name\:/}.first.split(/(:|;)/)
FullName = allData[2].sub(/^ /,'')
Email = allData[4].sub(/^ /,'')
puts "Hello: #{FullName}\n\n"
#pp [FullName, Email]

#### Parse Sample Info ####
sampleNames = Hash.new  ### s_name -> file(s)
sampleTypes = Array.new
File.open(sampleInfo,'r').each do |ln|
	ln.chomp!
	rr=ln.split(":")
	rr2=rr[1].split("=")
	sampleNames[rr2[0]]=rr2[1]
	sampleTypes.push(rr[0])
end
sampleTypes.uniq!

#### Parse Run Info ####
runVariables = Hash.new
File.open(runInfo,'r').each do |ln|
	ln.chomp!
	next if ln =~ /^#/
	next if ln =~ /^$/ # empty line
	rr=ln.split("=")
	value = rr[1]
	if value =~ /"/
		value.gsub!(/"/,'')
	end
	if value =~ /:/
		value = value.split(/:/)
	end
	runVariables[rr[0]] = value
	
end
#pp runVariables


newRedCapPrjtMap={'1'=>'SIMPLEXO','2'=>'Demokratos','3'=>'Pancreas PDX','4'=>'German Clinical Trial','5'=>'TNBC Custom Capture','6'=>'CIMBA WGS','7'=>'Familial Breast Cancer Exomes','8'=>'UPENN Data Sharing','9'=>'Pancreas mRNA','10'=>'Pancreas Exomes','11'=>'Pancreas SPORE CC','12'=>'COH Data Sharing','13'=>'Offsite Breast Cancer Family Registry','14'=>'Ovarian PDX'}

print "I have #{runVariables["SAMPLENAMES"].size} samples.\nDo you want to assign all these samples to a project? (Y/n)  "
onePrjtQue = $stdin.gets.chomp
## default to not setting to a project
## COME BACK TO THIS later.





#### FIND SAMPLES IN DATABASE ####
d = Time.new()
output = File.open("upload2redcap_#{d.strftime("%m-%d-%Y")}.csv","w")

aliases=[1,3,5,6,7]
sampleMap=Hash.new
File.readlines(dbFile).each_with_index do |ln, idx|
    rr=ln.split(/\,/).map{|m| m.sub(/^\"/,'').sub(/\"$/,'') }
	uid = rr.shift
	rr[0] = "#{uid}|#{rr[0]}"

    if idx == 0
		@header = rr
		# header after projects is dynamic...find sample aliase
		aliases.push(@header.index('sample_alias'))
		next
    end
	
	aliases.each do |e|
		#puts "looking at #{@header[e]}[#{e}]"
		if !rr[e].empty?
			next if rr[e] == "0"
			if sampleMap.has_key?(rr[e])
				next if rr[0] == sampleMap[rr[e]]
				if warningsOn
					puts "Warning! #{rr[e]} has multiple records. #{rr[0]} ~~ #{sampleMap[rr[e]]}"
				end
				sampleMap[rr[e]] = "#{sampleMap[rr[e]]}^#{rr[0]}"
			end
			sampleMap[rr[e]] = rr[0]
		end		
		
	end

	#break if idx > 30
    # if idx % 100 == 0
      # print " . "
    # end
    # if idx % 1000 == 0
      # puts " * "
    # end
	
end
#pp sampleMap
