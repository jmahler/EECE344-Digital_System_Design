
all: main.pdf

main.pdf: main.tex references.bib
	rubber --pdf $<

clean:
	-rm -f *.aux *.blg *.bbl *.log *.out *.toc
	-rm -f *.eps
