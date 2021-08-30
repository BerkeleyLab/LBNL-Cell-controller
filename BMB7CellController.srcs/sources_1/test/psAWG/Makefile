TEST_SOURCE = psAWG_tb.v psAWG.v

all: psAWG_tb.vvp

psAWG_tb.vvp: $(TEST_SOURCE)
	iverilog -Wall -o psAWG_tb.vvp $(TEST_SOURCE)

psAWG_tb.lxt test.dat: psAWG_tb.vvp
	vvp psAWG_tb.vvp -lxt2 >test.dat

test: test.dat

view: psAWG_tb.lxt
	case `uname` in \
    Darwin) open psAWG_tb.lxt psAWG_tb.gtkw & ;; \
    *) gtkwave psAWG_tb.lxt psAWG_tb.gtkw & ;; \
    esac

clean:
	rm -rf *.vvp *.lxt *.dat
