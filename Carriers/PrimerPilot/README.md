## Title: PrimerPilot SOP
 Author: Raymond Moore
 Started: Oct 2015


TODO: create an SOP

Make SOP for primer checking…(going to repeat this often, Breast & Panc. separate but equal)

1. Get all products from faidx - ref hg19.
3. Calc annealing temp for Primer & Primer Set (delta).
 * Input = Chunling's primer "bedfile"
 * Output = annealing temp, gc content, hairpin, size checks.
 1. Primer3 accepts seq, to check primer align.
 2. Webcrawl both Primer3 & IDT OligoAnalysis (ruby script)
4. Line up 58 – 60 – 62 degree primer designs & compare.
5. Run Steve's primer dimer eval script.
6. Pooling determinations/Conflicts (if pool already determined)
7. Blat all products - determine location ?


