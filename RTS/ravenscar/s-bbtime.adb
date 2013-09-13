------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                         S Y S T E M . B B . T I M E                      --
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
--  with Ada.Unchecked_Conversion;

with System.BB.Interrupts;
pragma Elaborate (System.BB.Interrupts);

with System.BB.Threads;
pragma Elaborate (System.BB.Threads);

with System.BB.Protection;

--  with System.Machine_Code;

with System.BB.Threads.Queues;
pragma Elaborate (System.BB.Threads.Queues);

with Interfaces; use Interfaces;
with System.BB.Board_Support.Bcm2835; use System.BB.Board_Support.Bcm2835;
with System.BB.CPU_Primitives;

package body System.BB.Time is

   use System.Multiprocessors;

   -----------------------
   -- Local definitions --
   -----------------------

   Cur_Time : Time;
   pragma Volatile (Cur_Time);
   --  Current clock in ticks.

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Alarm_Handler (Interrupt : Interrupts.Interrupt_ID);
   --  Handler for the alarm interrupt

   procedure Update_Alarm (Alarm : Time) is
      pragma Unreferenced (Alarm);
   begin
      null;
   end Update_Alarm;

   -------------------
   -- Alarm_Handler --
   -------------------

   procedure Alarm_Handler (Interrupt : Interrupts.Interrupt_ID) is
      pragma Unreferenced (Interrupt);

      Now             : Time;
      Wakeup_Thread   : Threads.Thread_Id;

      Status          : Unsigned_32;
      pragma Unreferenced (Status);

      use type Threads.Thread_States;

   begin
      --  Increment the tick.

      Now := Cur_Time + 1;
      Cur_Time := Now;

      --  Clear the interrupt
      AT_IRQCA := 0;

      --  The access to the queues must be protected

      Protection.Enter_Kernel;

      --  Extract all the threads whose delay has expired

      while Threads.Queues.Get_Next_Alarm_Time (CPU'First) <= Now loop

         --  Extract the task(s) that was waiting in the alarm queue and
         --  insert it in the ready queue.

         Wakeup_Thread := Threads.Queues.Extract_First_Alarm;

         --  We can only awake tasks that are delay statement

         pragma Assert (Wakeup_Thread.State = Threads.Delayed);

         Wakeup_Thread.State := Threads.Runnable;

         Threads.Queues.Insert (Wakeup_Thread);
      end loop;

      --  We have finished the modifications to the queues

      Protection.Leave_Kernel;

   end Alarm_Handler;

   -----------
   -- Clock --
   -----------

   function Clock return Time is
   begin
      return Cur_Time;
   end Clock;

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (T : Time) is
      Now               : Time;
      Self              : Threads.Thread_Id;
      Inserted_As_First : Boolean;

   begin
      Protection.Enter_Kernel;

      Now := Clock;

      Self := Threads.Thread_Self;

      --  Test if the alarm time is in the future

      if T > Now then

         --  Extract the thread from the ready queue. When a thread wants
         --  to wait for an alarm it becomes blocked.

         Self.State := Threads.Delayed;

         Threads.Queues.Extract (Self);

         --  Insert Thread_Id in the alarm queue (ordered by time) and if it
         --  was inserted at head then check if Alarm Time is closer than the
         --  next decrementer interrupt.

         Threads.Queues.Insert_Alarm (T, Self, Inserted_As_First);

      else
         --  If alarm time is not in the future, the thread must yield the CPU

         Threads.Queues.Yield (Self);
      end if;

      Protection.Leave_Kernel;
   end Delay_Until;

   ----------------------
   -- Get_Next_Timeout --
   ----------------------

   function Get_Next_Timeout (CPU_Id : CPU) return Time is
   begin
      return Threads.Queues.Get_Next_Alarm_Time (CPU_Id);
   end Get_Next_Timeout;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers is
      --  System_Frequency : constant := 250_000_000;
   begin
      Interrupts.Disable_Interrupt (AT_INT);

      AT_CTL    := 16#003E_0000#;
      --  "3E":Reset value; both timer and its IRQ are disabled

      AT_LOAD   := Unsigned_32 (Ticks_Per_Second) - 1;
      AT_RELOAD := Unsigned_32 (Ticks_Per_Second) - 1;
      --  Ticks_Per_Second uS, when Ticks_Per_Second=1000, the period is 1mS.

      AT_PREDIV := 16#0000_00F9#;
      --  Clock is System_Frequency/0xF9 =1 MHz, or 1 uS

      AT_IRQCA  := 0;   --  clear the pending bit

      Interrupts.Attach_Handler
        (Alarm_Handler'Access, Board_Support.Bcm2835.AT_INT);

      AT_CTL    := 16#003E_00A2#;
      --  "A": (8+2)both timer and its IRQ are enabled
      --  "2": 23 bit counter
      Interrupts.Enable_Interrupt (AT_INT);
   end Initialize_Timers;

end System.BB.Time;
