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


base="https://www.idtdna.com/calc/analyzer"



browser = Watir::Browser.new
browser.goto base


myQuery = Hash.new
lp=true

browser.div(:class => "textAreaStyle").textarea.set "ctctctatgggcagtcggtgattTATAAATACTGCAGTATAAAATAATTAT"
browser.button(:text => 'Analyze').click


##
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
  myQuery[ c[0].text ] = c[1].text
end


pp myQuery




exit



agent = Mechanize.new { |a| a.log = Logger.new("primer_check.log") }

pageIDT = agent.get(base)

queryIDT = pageIDT.at '#seqInput'
queryIDT.set_attribute  'value', "ctctctatgggcagtcggtgattTATAAATACTGCAGTATAAAATAATTAT"


rezIDT = agent.click( pageIDT.search('button').select{|b| b.text == "Analyze"}[0] )

anaTable = rezIDT.search("div div.row div.col-md-12 div.panel.panel-default table.table").first

#pageIDT.search('button').select{|b| b.text == "Analyze"}
#pp idtForm.forms


pg2 = agent.get("https://www.idtdna.com/calc/analyzer#OAResults")

div#OAResults.tab-pane.active



sleep rand(5) ## Don't hit server too hard. wait between 1-5 secs.



#             input
#id="seqInput"