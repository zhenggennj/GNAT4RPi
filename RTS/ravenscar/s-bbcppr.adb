------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . C P U _ P R I M I T I V E S            --
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
--  Modified by L. G. Zheng
with Interfaces; use Interfaces;

with System;
with System.Machine_Code;
with System.Storage_Elements;

--  The following four lines are Commented by L. G. Zheng

--  with System.BB.Threads.Queues;
--  with System.BB.Interrupts;
--  with System.BB.Protection;
--  with System.BB.Board_Support;

with Ada.Unchecked_Conversion;

with System.BB.Board_Support.Bcm2835; use System.BB.Board_Support.Bcm2835;

package body System.BB.CPU_Primitives is

--   procedure Dbg (N : Character);
--   pragma Import (C, Dbg);

   package SSE renames System.Storage_Elements;
   use type SSE.Integer_Address;
   use type SSE.Storage_Offset;

   Flag_F : constant Unsigned_32 := 2#0100_0000#;
   Flag_I : constant Unsigned_32 := 2#1000_0000#;
   --  Processor flags.

   procedure Set_Cpsr_C (Val : Unsigned_32);
   function Get_Cpsr return Unsigned_32;
   --  Setting and getting processor flags.

   ----------------
   -- Local data --
   ----------------

   SP  : constant Range_Of_Context :=  12;
   LR  : constant Range_Of_Context :=  13;
   Arg : constant Range_Of_Context :=  0;

   ------------------------
   -- Initialize_Context --
   ------------------------

   procedure Initialize_Context
     (Buffer          : not null access Context_Buffer;
      Program_Counter : System.Address;
      Argument        : System.Address;
      Stack_Pointer   : System.Address)
   is
   begin
      Buffer (SP) := Stack_Pointer;
      Buffer (LR) := Program_Counter;
      Buffer (Arg) := Argument;
   end Initialize_Context;

   -------------------------------
   -- Initialize_Floating_Point --
   -------------------------------

   procedure Initialize_Floating_Point is
   begin
      --  There is no floating point unit and therefore we have a null body

      null;
   end Initialize_Floating_Point;

   --------------
   -- Get_Cpsr --
   --------------

   function Get_Cpsr return Unsigned_32 is
      Res : Unsigned_32;
   begin
      System.Machine_Code.Asm ("mrs %0,cpsr",
                               Outputs => Unsigned_32'Asm_Output ("=r", Res),
                               Volatile => True);
      return Res;
   end Get_Cpsr;

   ----------------
   -- Set_Cpsr_C --
   ----------------

   procedure Set_Cpsr_C (Val : Unsigned_32) is
   begin
      System.Machine_Code.Asm ("msr cpsr_c,%0",
                               Inputs => Unsigned_32'Asm_Input ("r", Val),
                               Volatile => True);
   end Set_Cpsr_C;

   ------------------------
   -- Disable_Interrupts --
   ------------------------

   procedure Disable_Interrupts is
   begin
      Set_Cpsr_C (Get_Cpsr or Flag_I or Flag_F);
   end Disable_Interrupts;

   -----------------------
   -- Enable_Interrupts --
   -----------------------

   procedure Enable_Interrupts
     (Level : System.BB.Parameters.Interrupt_Level)
   is
   begin
      if Level = 0 then
         Set_Cpsr_C (Get_Cpsr and not (Flag_I or Flag_F));
      end if;
   end Enable_Interrupts;

end System.BB.CPU_Primitives;
