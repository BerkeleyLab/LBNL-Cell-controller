# Interaction between newad and auto-dependency generation is confusing.
# . and $(DSP_DIR) are different when building out-of-tree
VFLAGS_DEP += -I. -y . -y$(DSP_DIR)
VFLAGS += -I. -y . -y$(DSP_DIR) -I$(AUTOGEN_DIR)

TEST_BENCH = \
	writeBPMTestLink_tb

TGT_ := $(TEST_BENCH)
NO_CHECK =
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))

.PHONY: targets checks
targets: $(TGT_)
checks: $(CHK_)

CLEAN += $(TGT_) *_tb *.pyc *.bit *.in *.vcd *.lxt *~
CLEAN_DIRS += _xilinx __pycache__

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
	-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
	-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifneq (,$(findstring _view,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifneq (,$(findstring _check,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifeq (,$(MAKECMDGOALS))
    -include $(TEST_BENCH:%_tb=$(DEPDIR)/%_tb.d)
endif
