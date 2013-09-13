/* ---------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
--------------------------------------------------------------------------- */
/*  
Modified for Raspberry Pi by L. G. Zheng.
*/
#include <stddef.h>

void
rpi_main(void)
{
  main ();
}

void data_abort_pc (void)
{
}

void data_abort_C (void)
{
}

void __aeabi_unwind_cpp_pr0 (void)
{
  while (1) ;
}

#ifdef ENABLE_LAST_CHANCE_HANDLER
extern void put_exception (unsigned int) __attribute__ ((weak));

void __attribute__ ((weak)) __gnat_last_chance_handler (void)
{
  unsigned int addr = (int) __builtin_return_address (0);

  if (put_exception != NULL)
    put_exception (addr);

  while (1)
    ;
}
#endif
