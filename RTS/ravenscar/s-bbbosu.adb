------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                S Y S T E M . B B . B O A R D _ S U P P O R T             --
--                                                                          --
--                                  B o d y                                 --
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

--  Modified by L. G. Zheng for Raspberry Pi

with System.BB.Board_Support.Bcm2835; use System.BB.Board_Support.Bcm2835;
with System.Storage_Elements;         use System.Storage_Elements;
with System.BB.Time;

with Ada.Unchecked_Conversion;

package body System.BB.Board_Support is

   procedure Dbg (N : Character);
   pragma Import (C, Dbg);
   pragma Unreferenced (Dbg);

   ----------------------
   -- Initialize_Board --
   ----------------------

   procedure Initialize_Board is
   begin
      null;
   end Initialize_Board;

   function Level_Of_Interrupt
     (Interrupt_Priority : System.Any_Priority) return SBP.Interrupt_Level is
   begin
      pragma Assert (Interrupt_Priority /= 0);

      return SBP.Interrupt_Levels;
   end Level_Of_Interrupt;

   ---------------------------
   -- Priority_Of_Interrupt --
   ---------------------------

   function Priority_Of_Interrupt
     (Level : SBP.Interrupt_Level) return System.Any_Priority is
   begin
      --  Assert that it is a real interrupt

      pragma Assert (Level /= 0);

      return System.Max_Interrupt_Priority;
   end Priority_Of_Interrupt;

   function Ticks_Per_Second return Natural is
   begin
      return System.BB.Time.Ticks_Per_Second;
   end Ticks_Per_Second;
end System.BB.Board_Support;
