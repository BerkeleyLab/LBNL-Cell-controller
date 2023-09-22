# Makefile for tests
ECHO	:= echo
MKDIR	:= mkdir -p

THIS_MAKEF_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MAKEF_DIR := $(dir $(THIS_MAKEF_PATH))
GW_TB_DIR=$(THIS_MAKEF_DIR)../../gateware/tb

PROJECT_NAME=protocolTest
PARENT_DIR=$(lastword $(subst /, ,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

TSIM_DIR=$(THIS_MAKEF_DIR)../target/sim
CFLAGS += -Wpointer-arith -Wredundant-decls -Wunreachable-code -Wno-unused-parameter

DEFINES=-DTESTS

BUILD_DIR=bin

TOP_DIR=..
SRC_DIR=src

TRAFFIC_GEN_SOURCES=trafficGen.c \
										ipcfg.c \
										$(TSIM_DIR)/udp_io.c

PROTO_CHECK_SOURCES=protocolTest.c \
										ipcfg.c \

ifeq ($(strip $(MAKECMDGOALS)),traffic)
SOURCES=$(TRAFFIC_GEN_SOURCES)
PROJECT_NAME=trafficGen
else ifeq ($(strip $(MAKECMDGOALS)),protoCheck)
SOURCES=$(PROTO_CHECK_SOURCES)
PROJECT_NAME=protocolTest
else
SOURCES=
endif
ABS_SOURCES=$(abspath $(SOURCES))

INCLUDES= -I. \
					-I$(TOP_DIR)/$(SRC_DIR) \
					-I$(TSIM_DIR) \
					-I$(GW_TB_DIR)

# Translate this list of sources into a list of required objects
# in the output directory
objects = $(patsubst %.c,%.o,$(patsubst %.S,%.o,$(patsubst %.s,%.o,$(SOURCES))))

SOURCE_ROOT=$(abspath $(THIS_MAKEF_DIR)../../)
BUILD_ROOT=$(abspath $(BUILD_DIR))
OBJECTS = $(subst $(SOURCE_ROOT),$(BUILD_ROOT),$(patsubst %.c,%.o,$(abspath $(SOURCES))))
define bldobj
$(info $(1):$(2))
$(1):$(2)
	mkdir -p $(dir $(1))
	$(CC) -c -MMD -MT"$(patsubst %.c,%.d,$<)" $(CFLAGS) $(DEFINES) $(INCLUDES) -o $(1) $(2)
endef
$(foreach sf,$(ABS_SOURCES),$(eval $(call bldobj,$(subst $(SOURCE_ROOT),$(BUILD_ROOT),$(patsubst %.c,%.o,$(sf))),$(sf))))

$(info SOURCES=$(SOURCES))
$(info OBJECTS=$(OBJECTS))

.PHONY: all
all:$(BUILD_DIR)/$(PROJECT_NAME)

#$(BUILD_DIR)/%.o: $(TOP_DIR)/%.c
#	@$(ECHO) 'Compiling $<...'
#	$(MKDIR) $(dir $@)
#	$(CC) -c -MMD -MT"$(patsubst %.c,%.d,$<)" $(CFLAGS) $(DEFINES) $(addprefix -I,$(INCLUDES)) -o $@ $<

#$(BUILD_DIR)/trafficGen.o: trafficGen.c $(TRAFFIC_GEN_SOURCES)
#	@$(ECHO) 'Compiling $<...'
#	$(MKDIR) $(dir $@)
#	$(CC) -c -MMD -MT"$(patsubst %.c,%.d,$<)" $(CFLAGS) $(DEFINES) $(addprefix -I,$(INCLUDES)) -o $@ $<

$(BUILD_DIR)/$(PROJECT_NAME): $(OBJECTS)
	@$(ECHO) 'Linking $@...'
	$(CC) $(LDFLAGS) -Wl,-Map,$@.map $(INCLUDES) -o $@ $(OBJECTS)

.PHONY: traffic
traffic: $(BUILD_DIR)/trafficGen
	@$<

.PHONY: protoCheck
protoCheck: $(BUILD_DIR)/$(PROJECT_NAME)
	@$<

# Removes everything in the output directory
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)


