@  This is the vector set up for an BCM2835

	.section .vectors,"ax"
	.code 32
	.align 	0

@ This is not actally executed in this code stream. Instead it is
@ copied into the reloacted vector space.
@ NB When executing the first instruction in an abort/interrupt, the pc is 8 (ie 2 instructions)
@ ahead of the start of instruction being executed.
@ Hence,  for all vectors, the ldr loads the correct address into pc by looking at pc + 0x18.
@ NB We do not do branches because these would get screwed up by relocation.
@


        ldr   pc,v0		@ reset vector
        ldr   pc,v1		@ Undefined Instruction
        ldr   pc,v2		@ Software Interrupt
        ldr   pc,v3		@ Prefetch Abort
        ldr   pc,v4		@ Data Abort
        ldr   pc,v5		@ reserved
        ldr   pc,v6		@ IRQ handler
        ldr   pc,v7		@ FIQ Handler
v0:	    .long start
v1:	    .long undef_handler
v2:	    .long swi_handler
v3:	    .long prefetch_abort_handler
v4:	    .long data_abort_handler
v5:	    .long reserved_handler
v6:	    .long irq_handler
v7:	    .long undef_handler
