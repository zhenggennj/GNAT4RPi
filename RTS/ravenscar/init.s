@  This is the init for an AT91SAM7S64
@ This code is entered with interrupts disabled
@ This code should work as start code from flash or RAM.
@ It does not have to be placed at address 0 since it will copy the vectors
@ there if needed.
@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ Macros to do memory initialisation

	.macro  mem_copy,  source, source_end, dest
	ldr   r0,=\source
	ldr   r1,=\source_end
	ldr   r2,=\dest
	bl    mem_copy_func
	.endm

	.macro mem_initialise, dest, dest_end, val
	ldr   r0,=\dest
	ldr   r1,=\dest_end
	ldr   r2,=\val
	bl    mem_init_func
	.endm

	.macro mac_string str
	.string \str
	.endm


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


	.text
	.code 32
	.align 	0

	.global start
	.extern rpi_main

@
start:
@ zheng
@        mov sp,#0x8000
@       bl rpi_main
@ zheng

@ Disable interrupts (IRQ and FIQ). Should not have to do this, but
@ lets not assume anything
	mrs  r0,cpsr
	orr  r0,r0,#0xc0
	msr  cpsr_all,r0


@
@
@ Copy the vector table
@
vector_copy:
	mem_copy       __vectors_load_start__, __vectors_load_end__, __vectors_ram_start__

@
@ Initialise memory regions
@
data_copy:
	mem_copy       __data_load_start__, __data_load_end__, __data_ram_start__
ram_text_copy:
	mem_copy       __ramtext_load_start__, __ramtext_load_end__, __ramtext_ram_start__
bss_init:
	mem_initialise __bss_start__, __bss_end__, 0
stack_init_0:
	mem_initialise __stack_start__, __stack_end__, 0x6b617453 @ 'Stak'

@
@   Set up stacks etc.
@   We set up the irq and system stacks
@   We switch to system mode for further execution
@   NB Stacks should be 8-byte aligned for APCS
@   They should already be aligned, but we mask the values to make sure.
@
stack_init_1:
@ Set up Interrupt stack
        msr   CPSR_c,#0xD2 @ IRQ mode, IRQ, FIQ off
        ldr   sp, =__irq_stack__
@
@ Set up System stack
	msr   CPSR_c,#0xDF @ System mode , I and F bits set
	ldr   sp, =__system_stack__

@ Set up initial frame pointers etc
	mov     a2, #0		@ Second arg: fill value
	mov	fp, a2		@ Null frame pointer
	mov	r7, a2		@ Null frame pointer for Thumb

@ Kick into main code using interworking

	ldr r5,=rpi_main
        mov lr,pc
	bx  r5

@ If we get here then main returned -- bad!
main_returned:
	b main_returned



@
@ Dummy handlers
@
	.global undef_handler
	.global swi_handler
	.global prefetch_abort_handler
	.global data_abort_handler
	.global reserved_handler

undef_handler:
	b undef_handler
swi_handler:
	b swi_handler
prefetch_abort_handler:
	b prefetch_abort_handler

	.extern data_abort_pc
	.extern data_abort_C

data_abort_handler:
	ldr r0,=data_abort_pc
	str lr,[r0]
	msr   CPSR_c,#0xDF		@ System mode , I and F bits set (interrupts disabled)
	ldr r0,=data_abort_C
	mov lr,pc
	bx  r0
data_abort_C_returned:
	b data_abort_C_returned

reserved_handler:
	b reserved_handler



@ Little helper funcs


@ mem_copy_func r0 = source start, r1 = end of source, r2 = destination
@ Will not copy if source == destination
@ Will try to use ldm/stm if 16-byte aligned.
mem_copy_func:
	@ bail if source and dest addresses are the same
	cmp   r0,r2
	bxeq  lr

	@ test if all addressed are 16-byte aligned, if so use ldm/stm copy
	mov   r3,r0
	orr   r3,r3,r1
	orr   r3,r3,r2
	ands  r3,r3,#15
	beq     mcf_16_aligned

	@ else use 4-byte aligned loop
mcf_loop:
	cmp   r0,r1
	ldrlo r3,[r2],#4
	strlo r3,[r0],#4
	blo   mcf_loop
	bx    lr

mcf_16_aligned:
	cmp   r0,r1
	ldmloia r0!,{r3-r6}
	stmloia r2!,{r3-r6}
	blo   mcf_16_aligned
	bx    lr


@ mem_init_func: r0 = start address, r1 = end address, r2 is value to write
@ If start and end addresses are multiples of 16 then we use stms to do the
@ storing.
mem_init_func:
	orr   r3,r0,r1
	ands  r3,r2,#15
	beq   mif_16_aligned
mif_loop:
	cmp   r0,r1
	strlo r2,[r0],#4
	blo   mif_loop
	bx    lr

mif_16_aligned:
	mov   r3,r2
	mov   r4,r2
	mov   r5,r2
mif_16_loop:
	cmp   r0,r1
	stmloia r0!,{r2-r5}
	blo   mif_16_loop
	bx    lr

.globl PUT32
PUT32:
    str r1,[r0]
    bx lr

.globl GET32
GET32:
    ldr r0,[r0]
    bx lr

.globl dummy
dummy:
    bx lr
