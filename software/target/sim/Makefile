# Makefile for simulated platform
ECHO	:= echo
MKDIR	:= mkdir -p

PROJECT_NAME=ccsim
PARENT_DIR=$(lastword $(subst /, ,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

CFLAGS += -Wpointer-arith -Wredundant-decls -Wunreachable-code -Wno-unused-parameter

# TODO - allow switch between BMB7 and MARBLE builds
DEFINES=-DSIMULATION -DBWUDP_USE_REAL_GPIO_H -DMARBLE

BUILD_DIR=bin

TOP_DIR=../..
SRC_DIR=src
BMB7_DIR=target/cctrl_bmb7
MARBLE_DIR=target/cctrl_marble
SIM_DIR=target/sim
BWUDP_DIR=$(SRC_DIR)/bwudp

SOURCES :=  $(SRC_DIR)/aurora.c \
						$(SRC_DIR)/console.c \
						$(SRC_DIR)/eebi.c \
						$(SRC_DIR)/epics.c \
						$(SRC_DIR)/evr.c \
						$(SRC_DIR)/eyescan.c \
						$(SRC_DIR)/fastFeedback.c \
						$(SRC_DIR)/fofbEthernet.c \
						$(SRC_DIR)/frontPanel.c \
						$(SRC_DIR)/main.c \
						$(SRC_DIR)/pilotTones.c \
						$(SRC_DIR)/psAWG.c \
						$(SRC_DIR)/psWaveformRecorder.c \
						$(SRC_DIR)/qsfp.c \
						$(SRC_DIR)/util.c \
						$(SRC_DIR)/xadc.c \
						$(SIM_DIR)/simplatform.c \
						$(SIM_DIR)/uart_fifo.c \
						$(SIM_DIR)/udp_simple.c \
						$(BWUDP_DIR)/badger.c \
						$(BWUDP_DIR)/bwudp.c

INCLUDES= . \
					$(TOP_DIR)/$(SRC_DIR) \
					$(TOP_DIR)/$(MARBLE_DIR) \
					$(TOP_DIR)/$(BWUDP_DIR)

$(info "SOURCES =" $(SOURCES))

# Translate this list of sources into a list of required objects
# in the output directory
objects = $(patsubst %.c,%.o,$(patsubst %.S,%.o,$(patsubst %.s,%.o,$(SOURCES))))

#OBJECTS=$(addprefix $(BUILD_DIR)/,$(foreach var,$(objects),$(addprefix $(lastword $(subst /, ,$(dir $(var))))/,$(notdir $(var)))))
OBJECTS = $(addprefix $(BUILD_DIR)/,$(objects))

$(info "OBJECTS =" $(OBJECTS2))

.PHONY: all
all:$(BUILD_DIR)/$(PROJECT_NAME)

$(BUILD_DIR)/%.o: $(TOP_DIR)/%.c
	@$(ECHO) 'Compiling $<...'
	$(MKDIR) $(dir $@)
	$(CC) -c -MMD -MT"$(patsubst %.c,%.d,$<)" $(CFLAGS) $(DEFINES) $(addprefix -I,$(INCLUDES)) -o $@ $<

$(BUILD_DIR)/$(PROJECT_NAME): $(OBJECTS)
	@$(ECHO) 'Linking $@...'
	$(CC) $(LDFLAGS) -Wl,-Map,$@.map -o $@ $(OBJECTS)

# Removes everything in the output directory
#
.PHONY: clean
clean:
	$(RM) -r $(BUILD_DIR)/*
	$(RM) src/rev.h

.PHONY: run
run: $(BUILD_DIR)/$(PROJECT_NAME)
	$(BUILD_DIR)/$(PROJECT_NAME)
