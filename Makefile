.PHONY: clean apps %-flash %-dump %-debug %-gdb
.SECONDARY:
.DEFAULT_GOAL = apps

###############################################################################
#                          Source File Aggregation                            #
###############################################################################

SRCS     = $(wildcard src/*.c)
APP_SRCS = $(wildcard app/*.c)

###############################################################################
#                          Configuration Parameters                           #
###############################################################################

OBJECTS   = $(SRCS:.c=.o)
APP_OUTS  = $(APP_SRCS:app/%.c=bin/%.bin)
DEPS     += $(SRCS:.c=.d)
-include $(DEPS)

EDITOR    = vim

# common
OBJ_DIR   = bin
APP_DIR   = app
TOOLCHAIN = arm-none-eabi-
INCLUDES += -I include -I include/proc -I include/cmsis
CFLAGS   += $(INCLUDES) -Wall -Werror -pedantic -std=c99
LFLAGS   += -Wl,--gc-sections

# processor specific
CPU       = -mcpu=cortex-m4
FPU       = -mfpu=fpv4-sp-d16 -mfloat-abi=hard
MCU       = $(CPU) -mthumb $(FPU)
CFLAGS   += $(MCU) -Os -fdata-sections -ffunction-sections -fno-builtin
LFLAGS   += --specs=nosys.specs -Tlink.ld

###############################################################################
#                            Compiling and Linking                            #
###############################################################################

$(OBJECTS): | $(OBJ_DIR)
$(OBJ_DIR):
	@[ ! -d $(OBJ_DIR) ] && mkdir $(OBJ_DIR) 

# https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html
%.d: %.c
	@set -e; rm -f $@; \
	$(TOOLCHAIN)gcc -MM -MT '$*.o' $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

%.o: %.c
	$(TOOLCHAIN)gcc $(CFLAGS) -c -o $@ $<

%.bin: %.elf
	@$(TOOLCHAIN)objcopy -O binary $< $@
	+@printf "copying '$(notdir $<)' -> '$(notdir $@)' ("
	@stat --printf="%s bytes)\n" $@

$(OBJ_DIR)/%.elf: $(APP_DIR)/%.o $(OBJECTS)
	$(TOOLCHAIN)gcc $(CFLAGS) $^ $(LFLAGS) -Wl,-Map=$(OBJ_DIR)/$*.map -o $@

###############################################################################
#                         Programming and Debugging                           #
###############################################################################

%.dump: %.elf
		$(TOOLCHAIN)objdump -D $< > $@

%-dump: $(OBJ_DIR)/%.dump
		$(EDITOR) $<

JLINK_FILE = ./temp.jlink
JLINK_ARGS = -device STM32F407VG -if SWD -speed 4000 -autoconnect 1
%-flash: $(OBJ_DIR)/%.bin
	@echo "loadbin $<, 0x08000000" > $(JLINK_FILE)
	@echo "r"                     >> $(JLINK_FILE)
	@echo "exit"                  >> $(JLINK_FILE)
	JLinkExe $(JLINK_ARGS) -CommanderScript $(JLINK_FILE)
	@rm $(JLINK_FILE)

%-debug: $(OBJ_DIR)/%.bin
		JLinkGDBServer $(JLINK_ARGS)

%-gdb: $(OBJ_DIR)/%.elf
	$(TOOLCHAIN)gdb $<

###############################################################################
#                              Phony Targets                                  #
###############################################################################

clean:
	@find . -name '*.o' -delete
	@find . -name '*.d' -delete
	@find . -name '*.d.*' -delete
	@rm -rf $(OBJ_DIR)

apps: $(APP_OUTS)
