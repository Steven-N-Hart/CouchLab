require 'open-uri'
require 'nokogiri'
require 'mechanize'
require 'logger'
require 'pp'



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

agent = Mechanize.new { |a| a.log = Logger.new("primer_check.log") }

idtForm = agent.get(base)

pp idtForm.forms




sleep rand(5) ## Don't hit server too hard. wait between 1-5 secs.



#             input
#id="seqInput"