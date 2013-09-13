------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . C P U _ P R I M I T I V E S            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
--                     Copyright (C) 2003-2011, AdaCore                     --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
-- The porting of GNARL to bare board  targets was initially developed by   --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

--  This package contains the primitives which are dependent on the
--  underlying processor.

--  This is the ARM version of this package

with System;
with System.Parameters;
with System.BB.Parameters;

package System.BB.CPU_Primitives is
   pragma Preelaborate;

   ------------------------
   -- Context management --
   ------------------------

   Context_Buffer_Capacity : constant := 14;
   --  The ARM processor needs to save 14 registers.

   Context_Buffer_Size : constant :=
                           Context_Buffer_Capacity * System.Word_Size;
   --  Size calculated taken into account that the components are 32-bit.

   type Context_Buffer is private;
   --  This type contains the saved register set for each thread

   procedure Context_Switch;
   pragma Import (Asm, Context_Switch, "context_switch");
   --  Perform the context switch between the running_thread and the
   --  first_thread. The value of running_thread will be updated.

   procedure Initialize_Context
     (Buffer          : not null access Context_Buffer;
      Program_Counter : System.Address;
      Argument        : System.Address;
      Stack_Pointer   : System.Address);
   pragma Inline (Initialize_Context);
   --  Initialize_Context inserts inside the context buffer the default values
   --  for each register. The values for the stack pointer, the program
   --  counter, and argument to be passed are provided as arguments.

   ---------------------------------
   -- Interrupt and trap handling --
   ---------------------------------

   procedure Disable_Interrupts;
   --  All external interrupts (asynchronous traps) are disabled

   procedure Enable_Interrupts
     (Level : System.BB.Parameters.Interrupt_Level);
   --  Interrupts are enabled if they are above the value given by Level

   procedure Initialize_Floating_Point;
   --  Install the floating point trap handler in charge of performing
   --  floating point context switches.

private

   subtype Range_Of_Context is Natural range 0 .. Context_Buffer_Capacity - 1;
   --  Type used for accessing to the different elements in the context buffer

   type Context_Buffer is array (Range_Of_Context) of System.Address;
   for Context_Buffer'Size use Context_Buffer_Size;
   --  This array contains all the registers that the thread needs to save
   --  within its thread descriptor.
end System.BB.CPU_Primitives;
