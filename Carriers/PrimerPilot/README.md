## Title: PrimerPilot SOP
 Author: Raymond Moore
 
 Started: Oct 2015

*Important Decisions*

 * Gene specific sequences only [11/02/2015]


TODO: create an SOP

Make SOP for primer checking…(going to repeat this often, Breast & Panc. separate but equal)

Start with tab file: BED file_10-6-15.xlsx

|PrimerName |FWD Primer|REV Primer|Amplicon Count|hg19 Location (chr:start-end)|Product Length|
|-----------|----------|----------|--------------|-----------------------------|--------------|


1. Get all products from faidx - ref hg19.
 * Run = script
 * Input = tab file described above.
 * Output = same as input plus append product seq to tab file.
2. Calc annealing temp for Primer & Primer Set (delta).
 * Input = Chunling's primer "bedfile" w/ appended product seq from Step 1.
 * Output = annealing temp, gc content, hairpin, size checks.
 * Run = 
 1. Primer3 accepts seq, to check primer align.
 2. Webcrawl both Primer3 & IDT OligoAnalysis (ruby script)
4. Line up 58 – 60 – 62 degree primer designs & compare.
5. Run Steve's primer dimer eval script.
6. Pooling determinations/Conflicts (if pool already determined)
7. Blat all products - determine location ?


