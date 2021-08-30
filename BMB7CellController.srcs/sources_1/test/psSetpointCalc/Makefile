TEST_SOURCE = psSetpointCalc_tb.v psSetpointCalc.v

all: psSetpointCalc_tb.vvp

psSetpointCalc_tb.vvp: $(TEST_SOURCE)
	iverilog -Wall -o psSetpointCalc_tb.vvp $(TEST_SOURCE)

psSetpointCalc_tb.lxt test.dat: psSetpointCalc_tb.vvp
	vvp psSetpointCalc_tb.vvp -lxt2 >test.dat

test: test.dat

view: psSetpointCalc_tb.lxt
	case `uname` in \
    Darwin) open psSetpointCalc_tb.lxt psSetpointCalc_tb.gtkw & ;; \
    *) gtkwave psSetpointCalc_tb.lxt psSetpointCalc_tb.gtkw & ;; \
    esac

clean:
	rm -rf *.vvp *.lxt *.dat
