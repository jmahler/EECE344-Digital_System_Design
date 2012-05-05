
PDFs = SPI_LEDs_SW.pdf RAM_to_CPLD.pdf

all: $(PDFs)

%.pdf: %.ps
	epstopdf $<

clean:
	-rm -f $(PDFs)
