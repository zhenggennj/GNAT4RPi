/****************************************************************************
 *                                                                          *
 *                GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                  *
 *                                                                          *
 *                      C O N T E X T _ S W I T C H                         *
 *                                                                          *
 *                              Assembly File                               *
 *                                                                          *
 *                      Copyright (C) 2010-2011 AdaCore                     *
 *                                                                          *
 * GNAT is free software;  you can  redistribute it  and/or modify it under *
 * terms of the  GNU General Public License as published  by the Free Soft- *
 * ware  Foundation;  either version 3,  or (at your option) any later ver- *
 * sion.  GNAT is distributed in the hope that it will be useful, but WITH- *
 * OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.                                     *
 *                                                                          *
 * As a special exception under Section 7 of GPL version 3, you are granted *
 * additional permissions described in the GCC Runtime Library Exception,   *
 * version 3.1, as published by the Free Software Foundation.               *
 *                                                                          *
 * You should have received a copy of the GNU General Public License and    *
 * a copy of the GCC Runtime Library Exception along with this program;     *
 * see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    *
 * <http://www.gnu.org/licenses/>.                                          *
 *                                                                          *
 ****************************************************************************/

/* This file is the ARM specific implementation */
        
/* procedure context_switch.
   This routine performs a context switch between the two tasks that are
   specified in running_thread and first_thread. */
        
	.text
	.align 2

	.global context_switch
	.type context_switch,%function
context_switch:
        @ ip = running thread context
        ldr     ip, Lrun
        ldr     ip, [ip]

        @ Save context
        stmia   ip, {r0-r11,sp,lr}

        @ Running thread = first_thread
        ldr     ip, Lfirst
        ldr     ip, [ip]
        ldr     r0, Lrun
        str     ip, [r0]

        @ Restore context
        ldmia   ip, {r0-r11,sp,lr}
        bx lr

        .align 2
Lrun:
        .word   __gnat_running_thread_table
Lfirst:
        .word   first_thread_table

	.size context_switch, . - context_switch
