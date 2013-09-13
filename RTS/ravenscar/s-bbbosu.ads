------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                S Y S T E M . B B . B O A R D _ S U P P O R T             --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
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

--  This package defines constants and primitives used for handling the
--  peripherals available in the target board.

--  This is the ARM version of this package

with System;
with System.BB.Parameters;

package System.BB.Board_Support is
   pragma Preelaborate;

   package SBP renames System.BB.Parameters;

   -----------------------------
   -- Hardware initialization --
   -----------------------------

   procedure Initialize_Board;
   --  Procedure that performs the hardware initialization of the board

   function Ticks_Per_Second return Natural;
   pragma Inline (Ticks_Per_Second);
   --  Return number of clock ticks per second taking into account that the
   --  prescaler divides the system clock rate.

   ----------------
   -- Interrupts --
   ----------------

   function Priority_Of_Interrupt
     (Level : SBP.Interrupt_Level) return System.Any_Priority;
   pragma Inline (Priority_Of_Interrupt);
   --  Function to obtain the priority associated with an interrupt. It returns
   --  System.Any_Priority'First if Level is equal to zero (no interrupt).

   function Level_Of_Interrupt
     (Interrupt_Priority : System.Any_Priority) return SBP.Interrupt_Level;
   --  Function to obtain level associated with an interrupt priority. It
   --  returns System.Interrupt_Level'First if Priority is not defined.

end System.BB.Board_Support;
