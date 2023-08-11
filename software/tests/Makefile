# Makefile for tests
ECHO	:= echo
MKDIR	:= mkdir -p

PROJECT_NAME=protocolTest
PARENT_DIR=$(lastword $(subst /, ,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

CFLAGS += -Wpointer-arith -Wredundant-decls -Wunreachable-code -Wno-unused-parameter

DEFINES=-DTESTS

BUILD_DIR=bin

TOP_DIR=..
SRC_DIR=src

SOURCES :=  $(PARENT_DIR)/$(PROJECT_NAME).c

INCLUDES= . \
					$(TOP_DIR)/$(SRC_DIR)

# Translate this list of sources into a list of required objects
# in the output directory
objects = $(patsubst %.c,%.o,$(patsubst %.S,%.o,$(patsubst %.s,%.o,$(SOURCES))))

OBJECTS = $(addprefix $(BUILD_DIR)/,$(objects))

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
.PHONY: clean
clean:
	$(RM) -rf $(BUILD_DIR)
	$(RM) src/rev.h

.PHONY: run
run: $(BUILD_DIR)/$(PROJECT_NAME)
	$(BUILD_DIR)/$(PROJECT_NAME)
