------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--              S Y S T E M . B B . E X E C U T I O N _ T I M E             --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                       Copyright (C) 2011, AdaCore                        --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

with System.BB.Parameters;
with System.BB.Board_Support;
with System.BB.Threads.Queues;

with System.Multiprocessors;
with System.Multiprocessors.Fair_Locks;
with System.Multiprocessors.Spin_Locks;

with System.OS_Interface;

package body System.BB.Execution_Time is

   use type System.BB.Time.Time;
   use System.BB.Interrupts;
   use System.BB.Threads;
   use System.Multiprocessors;
   use System.Multiprocessors.Fair_Locks;
   use System.Multiprocessors.Spin_Locks;

   Interrupts_Execution_Time : array (Interrupt_ID) of System.BB.Time.Time :=
                                 (others => System.BB.Time.Time'First);
   --  Time counter for each interrupt

   Interrupt_Exec_Time_Lock : Fair_Lock := (Spinning => (others => False),
                                            Lock     => (Flag   => Unlocked));
   --  Protect access to interrupt time counters on multiprocessor systems

   CPU_Clock : array (CPU) of System.BB.Time.Time :=
                 (others => System.BB.Time.Time'First);
   --  Date of the last Interrupt

   Disabled : array (CPU) of Boolean := (others => True);
   --  If the CPU clock is disabled the next elapsed time will be discarded (to
   --  handle CPU idle time).

   ----------------------------
   -- Disable_Execution_Time --
   ----------------------------

   procedure Disable_Execution_Time is
      CPU_Id : constant CPU := System.OS_Interface.Current_CPU;
   begin
      Disabled (CPU_Id) := True;
   end Disable_Execution_Time;

   ----------------------------
   -- Global_Interrupt_Clock --
   ----------------------------

   function Global_Interrupt_Clock return System.BB.Time.Time is
      Sum : System.BB.Time.Time := System.BB.Time.Time'First;

   begin
      if System.BB.Parameters.Multiprocessor then

         --  Protect shared access on multiprocessor systems

         Lock (Interrupt_Exec_Time_Lock);
      end if;

      for Interrupt in Interrupt_ID loop
         Sum := Sum + Interrupts_Execution_Time (Interrupt);
      end loop;

      if System.BB.Parameters.Multiprocessor then
         Unlock (Interrupt_Exec_Time_Lock);
      end if;

      return Sum;
   end Global_Interrupt_Clock;

   ---------------------
   -- Interrupt_Clock --
   ---------------------

   function Interrupt_Clock
     (Interrupt : Interrupt_ID) return System.BB.Time.Time
   is
      Value : System.BB.Time.Time;

   begin
      if System.BB.Parameters.Multiprocessor then

         --  Protect shared access on multiprocessor systems

         Lock (Interrupt_Exec_Time_Lock);
      end if;

      Value := Interrupts_Execution_Time (Interrupt);

      if System.BB.Parameters.Multiprocessor then
         Unlock (Interrupt_Exec_Time_Lock);
      end if;

      return Value;
   end Interrupt_Clock;

   ----------------------
   -- Scheduling_Event --
   ----------------------

   procedure Scheduling_Event (Now : System.BB.Time.Time) is
      CPU_Id         : constant CPU := System.OS_Interface.Current_CPU;
      Last_CPU_Clock : constant System.BB.Time.Time := CPU_Clock (CPU_Id);
      Elapsed_Time   : System.BB.Time.Time;

   begin
      pragma Assert (Now >= Last_CPU_Clock);

      Elapsed_Time := Now - Last_CPU_Clock;

      --  Reset the clock

      CPU_Clock (CPU_Id) := Now;

      if Disabled (CPU_Id) then

         --  Discard the elapsed time and re-enable the clock

         Disabled (CPU_Id) := False;
         return;
      end if;

      if Current_Interrupt /= No_Interrupt
        and then Thread_Self.Active_Priority =
                   Board_Support.Priority_Of_Interrupt (Current_Interrupt)
      then
         --  This CPU currently executes an interrupt

         if System.BB.Parameters.Multiprocessor then

            --  Protect shared access on multiprocessor systems

            Lock (Interrupt_Exec_Time_Lock);
         end if;

         Interrupts_Execution_Time (Current_Interrupt) :=
           Interrupts_Execution_Time (Current_Interrupt) + Elapsed_Time;

         if System.BB.Parameters.Multiprocessor then
            Unlock (Interrupt_Exec_Time_Lock);
         end if;

      --  This CPU currently executes a task

      else
         Thread_Self.Execution_Time :=
           Thread_Self.Execution_Time + Elapsed_Time;
      end if;
   end Scheduling_Event;

   ------------------
   -- Thread_Clock --
   ------------------

   function Thread_Clock
     (Th : System.BB.Threads.Thread_Id) return System.BB.Time.Time
   is
   begin
      pragma Assert (Th /= Null_Thread_Id);

      --  If the thread Th is running, we need to add the elapsed time between
      --  the last scheduling and now.
      --  The thread Th is running if it is the current one and:
      --  * no interrupt is executed
      --  * or the interrupt triggered this thread.

      if Th = Thread_Self and then
        (Current_Interrupt = No_Interrupt
          or else Thread_Self.Active_Priority /=
                    Board_Support.Priority_Of_Interrupt (Current_Interrupt))
      then
         declare
            CPU_Id       : constant CPU := System.OS_Interface.Current_CPU;
            Now          : constant BB.Time.Time := System.BB.Time.Clock;
            Elapsed_Time : constant BB.Time.Time := Now - CPU_Clock (CPU_Id);
         begin
            return Th.Execution_Time + Elapsed_Time;
         end;

      else
         return Th.Execution_Time;
      end if;
   end Thread_Clock;

end System.BB.Execution_Time;
