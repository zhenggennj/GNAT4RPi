------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . I N T E R R U P T S                --
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
--  Modified for BCM2835 by L. G. Zheng

with Ada.Unchecked_Conversion;
with System.Storage_Elements;
with System.BB.CPU_Primitives;
--  with System.BB.Protection;
with System.BB.Threads;
with System.BB.Threads.Queues;
with System.BB.Board_Support.Bcm2835; use System.BB.Board_Support.Bcm2835;
with Interfaces; use Interfaces;

package body System.BB.Interrupts is

   procedure Dbg (N : Character);
   pragma Import (C, Dbg);
   pragma Unreferenced (Dbg);

   use type System.Storage_Elements.Storage_Offset;

   procedure Default_Isr (Id : Interrupt_ID);
   --  Default handlers.

   function Context_Switch_Needed return Boolean;
   pragma Import (Asm, Context_Switch_Needed, "context_switch_needed");

   ----------------
   -- Local data --
   ----------------

   Interrupt_Handlers : array (HW_Interrupt_ID) of Interrupt_Handler;

   Interrupt_Being_Handled : Interrupt_ID := No_Interrupt;
   pragma Atomic (Interrupt_Being_Handled);
   --  Interrupt_Being_Handled contains the interrupt currently being
   --  handled in the system, if any. It is equal to No_Interrupt when no
   --  interrupt is handled. Its value is updated by the trap handler.

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Irq_Handler;
   pragma Export (C, Irq_Handler, "irq_handler_ada");
   --  This wrapper procedure is in charge of setting the appropriate
   --  software priorities before calling the user-defined handler.

   --------------------
   -- Attach_Handler --
   --------------------

   procedure Attach_Handler (Handler : Interrupt_Handler;
                             Id      : Interrupt_ID) is
   begin
      --  Check that we are attaching to a real interrupt

      pragma Assert (Id /= No_Interrupt);

      --  Copy the user's handler to the appropriate place within the table

      Interrupt_Handlers (Id) := Handler;

   end Attach_Handler;

   -----------------------
   -- Current_Interrupt --
   -----------------------

   function Current_Interrupt return Interrupt_ID is
   begin
      return Interrupt_Being_Handled;
   end Current_Interrupt;

   -----------------------
   -- Interrupt_Wrapper --
   -----------------------

   procedure Irq_Handler
   is
      Cur_Interrupt_ID       : HW_Interrupt_ID;
      Self_Id         : constant Threads.Thread_Id := Threads.Thread_Self;
      Caller_Priority : constant Any_Priority :=
                          Threads.Get_Priority (Self_Id);

      Previous_Interrupt_ID : constant Interrupt_ID :=
                                   Interrupt_Being_Handled;

--      procedure Dbg_Hand (Addr : Unsigned_32; Len : Natural := 8);
--      pragma Import (Ada, Dbg_Hand, "display_hex");
--      procedure Dbg_u32 (Val : Unsigned_32; Len : Natural := 8);
--      pragma Import (Ada, Dbg_u32, "display_hex");
   begin
      --  Get current interrupt

      if IRQ_Pending ((AT_INT + 32) mod 96) then
         Cur_Interrupt_ID := AT_INT;
      else
         if IRQ_Pending ((REG1_HAS_PENDING + 32) mod 96) then
            if IRQ_Pending ((ST_CM0_INT + 32) mod 96) then
               Cur_Interrupt_ID := ST_CM0_INT;
            elsif IRQ_Pending ((ST_CM1_INT + 32) mod 96) then
               Cur_Interrupt_ID := ST_CM1_INT;
            elsif IRQ_Pending ((ST_CM2_INT + 32) mod 96) then
               Cur_Interrupt_ID := ST_CM2_INT;
            elsif IRQ_Pending ((ST_CM3_INT + 32) mod 96) then
               Cur_Interrupt_ID := ST_CM3_INT;
            elsif IRQ_Pending ((AUX_INT + 32) mod 96) then
               Cur_Interrupt_ID := AUX_INT;
            end if;
         else
            if IRQ_Pending ((REG2_HAS_PENDING + 32) mod 96) then
               if IRQ_Pending ((I2C_SPI_SLV_INT + 32) mod 96) then
                  Cur_Interrupt_ID := I2C_SPI_SLV_INT;
               elsif IRQ_Pending ((PWA0_INT + 32) mod 96) then
                  Cur_Interrupt_ID := PWA0_INT;
               elsif IRQ_Pending ((PWA1_INT + 32) mod 96) then
                  Cur_Interrupt_ID := PWA1_INT;
               elsif IRQ_Pending ((SMI_INT + 32) mod 96) then
                  Cur_Interrupt_ID := SMI_INT;
               elsif IRQ_Pending ((GPIO_INT0 + 32) mod 96) then
                  Cur_Interrupt_ID := GPIO_INT0;
               elsif IRQ_Pending ((GPIO_INT1 + 32) mod 96) then
                  Cur_Interrupt_ID := GPIO_INT1;
               elsif IRQ_Pending ((GPIO_INT2 + 32) mod 96) then
                  Cur_Interrupt_ID := GPIO_INT2;
               elsif IRQ_Pending ((GPIO_INT3 + 32) mod 96) then
                  Cur_Interrupt_ID := GPIO_INT3;
               elsif IRQ_Pending ((I2C_INT + 32) mod 96) then
                  Cur_Interrupt_ID := I2C_INT;
               elsif IRQ_Pending ((SPI_INT + 32) mod 96) then
                  Cur_Interrupt_ID := SPI_INT;
               elsif IRQ_Pending ((PCM_INT + 32) mod 96) then
                  Cur_Interrupt_ID := PCM_INT;
               elsif IRQ_Pending ((UART_INT + 32) mod 96) then
                  Cur_Interrupt_ID := UART_INT;
               end if;
            end if;
         end if;
      end if;

      --  Store the interrupt being handled

      Interrupt_Being_Handled := Integer (Cur_Interrupt_ID);

      --  Then, we must set the appropriate software priority corresponding
      --  to the interrupt being handled. It comprises also the appropriate
      --  interrupt masking.

      Threads.Queues.Change_Priority (Self_Id, Max_Interrupt_Priority);

      --  Call the user handler
--      if Interrupt /= 1 then
--         Dbg_Hand (Vec);
--         Dbg ('H');
--      end if;
      Interrupt_Handlers (Cur_Interrupt_ID).all (Cur_Interrupt_ID);

      --  Restore the software priority to the state before the interrupt
      --  happened. Interrupt unmasking is not done here (it will be done
      --  later by the interrupt epilogue).

      Threads.Queues.Change_Priority (Self_Id, Caller_Priority);

      --  Restore the interrupt that was being handled previously (if any)

      Interrupt_Being_Handled := Previous_Interrupt_ID;

      if Context_Switch_Needed then
         CPU_Primitives.Context_Switch;
      end if;
   end Irq_Handler;

   ----------------------------
   -- Within_Interrupt_Stack --
   ----------------------------

   function Within_Interrupt_Stack
     (Stack_Address : System.Address) return Boolean
   is
      pragma Unreferenced (Stack_Address);
   begin
      --  Always return false as the task stack is always used.
      return False;
   end Within_Interrupt_Stack;

   procedure Default_Isr (Id : Interrupt_ID) is
      pragma Unreferenced (Id);
   begin
      null;
   end Default_Isr;

   ---------------------------
   -- Initialize_Interrupts --
   ---------------------------

   procedure Initialize_Interrupts is
   begin
      --  Disable all interrupt lines.
      IRQ_DISABLE1      := 16#FFFF_FFFF#;
      IRQ_DISABLE2      := 16#FFFF_FFFF#;
      IRQ_DISABLE_BASIC := 16#FFFF_FFFF#;

      --  No interrupt lines handled by the FIQ handler.
      FIQ_CTRL  := 0;   --  disabled when bit 7 is 0. bit6:0 are FIQ SRC ID

      for I in HW_Interrupt_ID loop
         Attach_Handler (Default_Isr'Access, I);
      end loop;

   end Initialize_Interrupts;

   procedure Enable_Interrupt (Id : HW_Interrupt_ID) is
   begin
      IRQ_Enable (Id) := Set;
   end Enable_Interrupt;

   procedure Disable_Interrupt (Id : HW_Interrupt_ID) is
   begin
      IRQ_Disable (Id) := Set;
   end Disable_Interrupt;

end System.BB.Interrupts;
