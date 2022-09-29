all: DSP.svg FirmwareBPMreadout.svg FirmwareCellReadout.svg

%.svg: %.pdf
	pdf2svg $< $@

%.pdf: %.graffle
	echo "Use OmniGraffle.app to export $< to pdf"

clean:
	rm -f *.pdf *.svg
