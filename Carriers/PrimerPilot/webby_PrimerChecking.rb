require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'logger'
require 'pp'
require 'watir'

def reverseComp(str)
  compliment={'A'=>"T",'T'=>"A",'C'=>"G",'G'=>"C"}
  return str.upcase.split(//).map{|a| compliment[a]}.join.reverse
end


### Usage: ruby webby_OligoAnalyzer.rb -f example.tsv
#### Help Statement ####
if ARGV[0]=='-h' || ARGV[0]=='--help'
  usageStr="Usage: ruby  This script will submit primer pairs to OligoAnalyzer.\n\n"
  usageStr+="\t-f <input file> [required]\n"
  usageStr+="\t-n <nnnnn> \n"
  usageStr+="\t\tFile Format:  PrimerName   Forward Sequence\n"
  puts usageStr+"\n"
  exit 0
end
opt = Hash[*ARGV]



#### Check Input Params ####
if !opt.has_key?('-f')
  puts "Missing input file!"
  exit 1
end

inputFile=opt['-f']
outputFile= inputFile.sub('seq.tsv', 'check.tsv')


ihaveoutputalready=false
existingOutput=Hash.new
if File.exist?(outputFile)
  File.readlines(outputFile).each_with_index do |ln, idx|
    nom=ln.split(/\t/)[0]
    existingOutput[nom]=idx
  end
  puts "OUTPUT EXISTS: [#{outputFile}] #{existingOutput.size-1} lines"
  ihaveoutputalready=true
  output = File.open( outputFile,"a" )
else
  output = File.open( outputFile,"w" )
end


base="https://www.idtdna.com/calc/analyzer"
primer3Base="http://bioinfo.ut.ee/primer3/"
browser = Watir::Browser.new
browser.driver.manage.timeouts.implicit_wait = 45 #45 seconds (default 30)
browser.goto base
agent = Mechanize.new




File.foreach(inputFile).with_index do |line, line_num|
  line.chomp!
  next if line_num == 0
 # if line_num > 1
 #   break
 # end

  row = line.split(/\t/)

  #pp [line_num, ihaveoutputalready, existingOutput.has_key?(row[0]), row[0]]

  ### skip rows that have already been done
  next if ihaveoutputalready && existingOutput.has_key?(row[0])


  if line_num % 40 == 0
    browser.goto base
  end


  adpt = /^[[:lower:]]+/.match(row[1])[0]
  adptMt = /^[[:lower:]]+/.match(row[2])[0]
  pNom = row[0].sub(/_(F|R)(\d+)$/, '_P\2')
  rHash = {"PrimerName"=>row[0],"Pair"=>pNom,"Seq"=>row[1],"MateSeq"=>row[2],"Adapter"=>adpt,"MateAdapter"=>adptMt,"NumAmps"=>row[3],
            "Location"=>row[4],"Size"=>row[5].sub('hp','').to_i,"ProductSeq"=>row[6]}


  #myQuery = Hash.new
  lp=true
  browser.div(:class => "textAreaStyle").textarea.set rHash["Seq"]      #"ctctctatgggcagtcggtgattTATAAATACTGCAGTATAAAATAATTAT"
  browser.button(:text => 'Analyze').click
  targetTbl = browser.div(:id => "OAResults").when_present.table.when_present   ##### div is there before table, before click

=begin
## Loop to wait for results to return from server.
  i=0
  while lp==true
    sleep 1
    if ! browser.div(:id => "OAResults").when_present.exists
      lp=false
    end
    i+=1
    if i > 120   ## approx 2 mins.
      $stderr.puts "Unable to reach results!! Quit."
      exit
    end
  end
=end
 ##  browser.div(:id => "OAResults").wait_until_present

  targetTbl.rows.each do |r|
    c = r.cells
    rHash[ "IDT_"+c[0].text ] = c[1].text
  end

  sleep (rand(8)+2) ## Don't hit server too hard. wait between 1-8 secs.


  form = agent.get(primer3Base).form_with(:id=>'primer3web')
  form.PRIMER_TASK="check_primers"
  form.SEQUENCE_PRIMER = rHash["Seq"].split(//).last(36).join
  form.SEQUENCE_PRIMER_REVCOMP = rHash["MateSeq"].split(//).last(36).join
  form.SEQUENCE_ID=["PrimerName"]

  amendedSeq= rHash["Adapter"]+rHash["ProductSeq"]+reverseComp(rHash["MateAdapter"]) rescue ''
  form.SEQUENCE_TEMPLATE=      amendedSeq
  #form.PRIMER_THERMODYNAMIC_OLIGO_ALIGNMENT=0
  form.PRIMER_OPT_SIZE=28
  form.PRIMER_MAX_SIZE=36
  form.PRIMER_MIN_TM=0.0
  form.PRIMER_MAX_TM=100.0
  form.PRIMER_PRODUCT_SIZE_RANGE="100-300"
  form.PRIMER_MAX_SELF_ANY=800.00
  form.PRIMER_MAX_SELF_END=300.00

  rez = form.submit( form.button_with(:name=>"Pick Primers"))

  p3text = rez.search("pre")[0].text.split("\n")


  p3Head =  p3text[7].upcase.split(/\s+/)
  p3left =  p3text[8].upcase.split(/\s+/)
  p3right =  p3text[9].upcase.split(/\s+/)


  for i in 1..p3Head.size-1
    rHash["P3_Left"+p3Head[i]] = p3left[i+1]
    rHash["P3_Mate"+p3Head[i]] = p3right[i+1]
  end

  if line_num == 1
    output.puts rHash.map{|k,v| "#{k}"}.join("\t")
  end

  output.puts rHash.map{|k,v| "#{v}"}.join("\t")

  ##pp rHash
  puts "LINE: #{line_num}"

end






