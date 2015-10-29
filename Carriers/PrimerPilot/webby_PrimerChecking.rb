require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'logger'
require 'pp'
require 'watir'



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
output = File.open( outputFile,"w" )
#outHeader=[]


base="https://www.idtdna.com/calc/analyzer"
browser = Watir::Browser.new
browser.goto base

File.foreach(inputFile).with_index do |line, line_num|
  #puts "#{line_num}: #{line}"
  line.chomp!

  next if line_num == 0
  #if line_num > 1
  #  break
  #end

  row = line.split(/\t/)

  adpt = /^[[:lower:]]+/.match(row[1])[0]
  pNom = row[0].sub(/_(F|R)(\d+)$/, '_S\2')
  rHash = {"PrimerName"=>row[0],"Pair"=>pNom,"Seq"=>row[1],"MateSeq"=>row[2],"Adapter"=>adpt,"NumAmps"=>row[3],
            "Location"=>row[4],"Size"=>row[5].sub('hp','').to_i,"ProductSeq"=>row[6]}



  #myQuery = Hash.new
  lp=true
  browser.div(:class => "textAreaStyle").textarea.set rHash["Seq"]      #"ctctctatgggcagtcggtgattTATAAATACTGCAGTATAAAATAATTAT"
  browser.button(:text => 'Analyze').click


## Loop to wait for results to return from server.
  i=0
  while lp==true
    sleep 1
    if ! browser.div(:id => "OAResults").nil?
      lp=false
    end
    i+=1
    if i > 120   ## approx 2 mins.
      $stderr.puts "Unable to reach results!! Quit."
      exit
    end
  end

  targetTbl = browser.div(:id => "OAResults").table

##pp targetTbl

  targetTbl.rows.each do |r|
    c = r.cells
#    myQuery[ c[0].text ] = c[1].text
    rHash[ c[0].text ] = c[1].text
  end


  #pp myQuery



  sleep rand(5) ## Don't hit server too hard. wait between 1-5 secs.


  if line_num == 1
    output.puts rHash.map{|k,v| "#{k}"}.join("\t")
  end

  output.puts rHash.map{|k,v| "#{v}"}.join("\t")

  #pp rHash



end








