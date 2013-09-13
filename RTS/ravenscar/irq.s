@  IRQ wrappers.
        
        .text
        .code 32
        .align   2

        .global irq_handler
irq_handler:

@ Save registers on stack
        sub     r14,r14,#4 @ fix up for return
        ldr     sp, =__irq_stack__
        stmdb   sp,{r11,r12,r14}
        mrs     r11,spsr
        mov     r12,sp

@ swich to system mode.
        msr     cpsr_c,#0xDF

@ Save registers.
        stmfd   sp!,{r0-r3,r9,r11,lr}

        ldmdb   r12,{r0,r1,r2}	@ ie r11,r12,r14
        stmfd   sp!,{r0,r1,r2}

@ Call the function
        bl      irq_handler_ada

@ pop stack
        ldr     r12, =__irq_stack__
        ldmfd   sp!,{r0,r1,r2}
        stmdb   r12,{r0,r1,r2} @ ie r11,r12,lr
        ldmfd   sp!,{r0-r3,r9,r11,lr}

@ swich to interrupt mode and disable IRQs and FIQs
        msr     cpsr_c,#0xD2

@ Restore spsr
        msr     spsr_all,r11

@ Return from interrupt (unstacking the modified r14)
        ldmdb   sp,{r11,r12,pc}^
