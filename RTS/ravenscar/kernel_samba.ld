/* SAM7 linker script source.
 *  This file must be run through a sed script to
 *  generate an ldscript suitable for either a ram or rom image.
 *
 *  The sed script achieves this by selectively copying the lines
 *   with ROM_ONLY and RAM_ONLY.
 *
 *  This script is for a system that runs with the memory 
 *  mapped  so that ram is visible at both 0 and 2M.
 *
 *  Notes on alignment:
 *  1) Sections should be 4-byte aligned otherwise ARM fetches
 *     will be misaligned.
 *  2) The stack should be 8-byte aligned for the APCS. That's because STRD
 *     and LDRD assume that they are on 8-byte boundaries.
 *  3) Align 16 is a good idea for any copied or initialised sections because
 *     this allows the faster LDM/STM code to run instead.
 */


/* 
 * Memory definitions.
 */

/* BCM2835  */

MEMORY
{
   vector_ram : ORIGIN = 0, LENGTH = 64
/* Samba needs space reserved up to 8k */
/* ram : ORIGIN = 0x8000 + 8k, LENGTH = 0x10000 - 8k */
 ram : ORIGIN = 0x8000, LENGTH = 140000000 
}


RAM_BASE = 0x8000;
RAM_SIZE = 140000000;

SECTIONS {

/* The vectors are at 0, but since this is overlapped with 
 * the ram area we need to reserve some space for the vector
 * table
 */
.vectors : {
    KEEP(*(.vectors))
    . = ALIGN(16);
} > vector_ram
 AT> ram

__vectors_ram_start__  = ADDR(.vectors);
__vectors_ram_end__    = (ADDR(.vectors) + SIZEOF(.vectors));
__vectors_load_start__ = LOADADDR(.vectors);
__vectors_load_end__ = (LOADADDR(.vectors) + SIZEOF(.vectors));

/* .text is the main program area. This is stored in flash or
 * RAM depending on the build type.
 */

.text : {
    . = ALIGN(16);
    * (*.text *.text.* *.glue*)
    . = ALIGN(16);
    * (*.rodata *.rodata.*)
    . = ALIGN(16);
}
 > ram

  .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) }
 > ram
   PROVIDE_HIDDEN (__exidx_start = .);

  .ARM.exidx   : { *(.ARM.exidx* .gnu.linkonce.armexidx.*) }
 > ram
   PROVIDE_HIDDEN (__exidx_end = .);

/*
 * data is initialised data. This has two addresses:
 * VMA: run-time address
 * LMA: load address.
 * For a ram build, these addresses are the same and since the data 
 * is loaded into the correct address there is no need to copy it.
 * For a rom build, the LMA is where the data is stored in rom and
 * the init code copies it into ram for run-time.
 *
 * NB LOADADDR is the same as ADDR if the VMA and LMA are the same.
 */

/*
 * .ram_text is code that is relocated to RAM for execution. 
 * Typical usage is flash programming code that needs to be in RAM while the
 * flash is busy.
 * NB We copy all program (text) and rodata into the RAM.
 */


.ram_text : {
    . = ALIGN(16);
    *.oram(*.text *.text.* *.glue*)
    . = ALIGN(16);
    *.oram(*.rodata *.rodata.*)
    . = ALIGN(16);
} > ram

__ramtext_ram_start__ = ADDR(.ram_text);
__ramtext_ram_end__   = ADDR(.ram_text) + SIZEOF(.ram_text);
__ramtext_load_start__ = LOADADDR(.ram_text); 
__ramtext_load_end__ = __ramtext_load_start__ + SIZEOF(.ram_text) ;

.data : {
    * (*.data *.data.*)
    . = ALIGN(16);
} > ram 

/* LOADADDR is the same as the ADDR if it is a ram build */
__data_ram_start__ = ADDR(.data);
__data_ram_end__   = ADDR(.data) + SIZEOF(.data);
__data_load_start__ = LOADADDR(.data); 
__data_load_end__ = __data_load_start__ + SIZEOF(.data) ;





/*
 * The stack is placed in ram.
 * The stack does not have to be initialised, but we do this
 * to monitor stack usage.
 * NB The stack needs to be 8-byte aligned, but we align it to 16 bytes.
 *
 * Notes about stack usage:
 * 1) Stack grows down.
 * 2) When an interrupt service routine is entered, it starts by using the
 * irqStack. If the interrupts are nesting then we have to swith to the 
 * system (or some other non-irq) stack. For this reason, the irq stack 
 * only needs to be big enough to hold a few registers for nested mode and the
 * real stack usage is on the system stack.
 */

.stack  : {
	/* irq stack */
	. += 0x80 ;
	. = ALIGN(16);
	__irq_stack__ = . ;

	/* system stack */
	__system_stack_bottom__ = . ;
        __stack_start = .;
	. += 0x400 ;
	. = ALIGN(16);
	__system_stack__ = .;
        __stack_end = .;
	__system_stack_top__ = . ;

} > ram

__stack_start__ = ADDR(.stack);
__stack_end__   = (ADDR(.stack) + SIZEOF(.stack));

/* bss is zero initialised data */
.bss : {
    * (*.bss *.bss.*)
    . = ALIGN(16);
    __bss_end__ = . ;
} > ram

__bss_start__ = ADDR(.bss);
__bss_end__   = (ADDR(.bss) + SIZEOF(.bss));

/* end = __bss_end__ ;  used by malloc */

__free_ram_start__ = __bss_end__ ;
__free_ram_end__ = (RAM_BASE + RAM_SIZE);


REPORTME_RAM_TOP = __bss_end__ ;
REPORTME_FREE_RAM_SIZE = __free_ram_end__ - __free_ram_start__;

}
