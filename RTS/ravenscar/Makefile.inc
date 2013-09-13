# -*- Makefile -*- for nxt ravenscar.
.SUFFIXES : .owav .wav

CROSS=arm-eabi-
CFLAGS?=-Os -g
RM=del

# KERN_OBJS = vectors.o init.o main.o irq.o context_switch-bb-arm.o
KERN_OBJS =  vectors.o init.o main.o irq.o context_switch-bb-arm.o

LIBGCC:=$(shell $(CROSS)gcc -print-libgcc-file-name)

all: $(PRG)

$(PRG): $(KERN_OBJS) $(WAV_OBJS) force
	$(CROSS)gnatmake -a $(CFLAGS) --RTS=$(RAVENSCAR_SRC)/../rts-raven \
	-I$(RAVENSCAR_SRC) -I$(RAVENSCAR_SRC)/../drivers \
	$(PRG) \
	-largs -nostdlib -nostdinc $(KERN_OBJS) $(WAV_OBJS)  \
	-T $(RAVENSCAR_SRC)/kernel_samba.ld  \
	$(LIBGCC) \
	-Wl,-z,max-page-size=4096 -Wl,-cref,-Map,$@.map

GCC_COMPILE=$(CROSS)gcc -c -o $@ $(CFLAGS) $<

main.o: $(RAVENSCAR_SRC)/../drivers/main.c
	$(GCC_COMPILE) -DENABLE_LAST_CHANCE_HANDLER

vectors.o: $(RAVENSCAR_SRC)/vectors.s
	$(GCC_COMPILE)

init.o: $(RAVENSCAR_SRC)/init.s
	$(GCC_COMPILE)

context_switch-bb-arm.o: $(RAVENSCAR_SRC)/context_switch-bb-arm.S
	$(GCC_COMPILE)

irq.o: $(RAVENSCAR_SRC)/irq.s
	$(GCC_COMPILE)

clean:
	$(RM) -f *.o *~ b~* $(PRG) *.ali *.map *.owav *.bin *.list *.pp *.npp

##.wav.owav:
$(WAV_OBJS): $(WAV_NAME)
	@echo "Converting $< to $(notdir $@)"
	$(CROSS)objcopy -I binary -O elf32-littlearm -B arm \
	--redefine-sym _binary_$(subst .,,$(subst /,_,$(basename $<)))_wav_start=$(basename $(notdir $<))_wav_start \
	--redefine-sym _binary_$(subst .,,$(subst /,_,$(basename $<)))_wav_end=$(basename $(notdir $<))_wav_end \
	--redefine-sym _binary_$(subst .,,$(subst /,_,$(basename $<)))_wav_size=$(basename $(notdir $<))_wav_size \
	$< $@
force:
