# Default compile flags.
CFLAGS=-Os -g

# Kernel path
RAVENSCAR_SRC=../../RTS/ravenscar

# Main subprogram.
PRG=blinker01

include $(RAVENSCAR_SRC)/Makefile.inc

ARMGNU=arm-eabi
all:
#	$(ARMGNU)-objdump -D $(PRG) > $(PRG).list
	$(ARMGNU)-objcopy $(PRG) -O binary $(PRG).bin

