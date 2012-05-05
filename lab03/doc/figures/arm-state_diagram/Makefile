
#OPTS=-Nfontsize=10 -Efontsize=10
OPTS=

all: arm-state_diagram.pdf

arm-state_diagram.eps: arm-state_diagram.dot
	dot -Teps $< $(OPTS) -o $@

arm-state_diagram.pdf: arm-state_diagram.eps
	epstopdf $<
