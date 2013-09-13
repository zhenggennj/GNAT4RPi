------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . P R O T E C T I O N                --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2011, AdaCore                     --
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
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The port of GNARL to bare board targets was initially developed by the   --
-- Real-Time Systems Group at the Technical University of Madrid.           --
--                                                                          --
------------------------------------------------------------------------------

pragma Restrictions (No_Elaboration_Code);

with System.BB.CPU_Primitives;
with System.BB.Parameters;
with System.BB.Board_Support;
with System.BB.Threads;
with System.BB.Time;

with System.BB.Threads.Queues;
pragma Elaborate (System.BB.Threads.Queues);

package body System.BB.Protection is

   --  Import System.BB.Execution_Time procedures as weak symbols to enable
   --  execution time computation only when needed. See s-bbexti.ads.

   procedure Scheduling_Event (Now : System.BB.Time.Time);
   pragma Import (Ada, Scheduling_Event, "__gnarl_scheduling_event");
   pragma Weak_External (Scheduling_Event);

   procedure Disable_Execution_Time;
   pragma Import (Ada, Disable_Execution_Time,
                    "__gnarl_disable_execution_time");
   pragma Weak_External (Disable_Execution_Time);

   ------------------
   -- Enter_Kernel --
   ------------------

   procedure Enter_Kernel is
   begin
      --  Interrupts are disabled to avoid concurrency problems when modifying
      --  kernel data. This way, external interrupts cannot be raised.

      CPU_Primitives.Disable_Interrupts;
   end Enter_Kernel;

   ------------------
   -- Leave_Kernel --
   ------------------

   procedure Leave_Kernel is
      use type System.BB.Threads.Thread_Id;
      use type System.BB.Threads.Thread_States;

   begin
      --  Interrupts are always disabled when entering here

      --  Wake up served entry calls

      if Parameters.Multiprocessor
        and then Wakeup_Served_Entry_Callback /= null
      then
         Wakeup_Served_Entry_Callback.all;
      end if;

      --  If there is nothing to execute (no tasks or interrupt handlers) then
      --  we just wait until there is something to do. It means that we need to
      --  wait until there is any thread ready to execute. Interrupts are
      --  handled just after enabling interrupts.

      if Threads.Queues.First_Thread = Threads.Null_Thread_Id then
         --  There is no task ready to execute so we need to wait until there
         --  is one, unless we are currently handling an interrupt.

         --  In the meantime, we put the task temporarily in the ready queue
         --  so interrupt handling is performed normally. Note that the task
         --  is inserted in the queue but its state is not Runnable.

         Threads.Queues.Insert (Threads.Queues.Running_Thread);

         --  Update Execution Time

         if Scheduling_Event'Address /= System.Null_Address then
            Scheduling_Event (System.BB.Time.Clock);
         end if;

         --  CPU goes to idle loop, we can disable the CPU clock

         if Disable_Execution_Time'Address /= System.Null_Address then
            Disable_Execution_Time;
         end if;

         --  Wait until a task has been made ready to execute (including the
         --  one that has been temporarily added to the ready queue).

         while Threads.Queues.First_Thread = Threads.Queues.Running_Thread
           and then Threads.Queues.Running_Thread.State /= Threads.Runnable
           and then Threads.Queues.Running_Thread.Next = Threads.Null_Thread_Id
         loop
            --  Allow all external interrupts for a while

            CPU_Primitives.Enable_Interrupts (0);
            CPU_Primitives.Disable_Interrupts;
         end loop;

         --  A task has been made ready to execute. We remove the one that was
         --  temporarily inserted in the ready queue, if needed.

         if Threads.Queues.Running_Thread.State /= Threads.Runnable then
            Threads.Queues.Extract (Threads.Queues.Running_Thread);
         end if;
      end if;

      --  We need to check whether a context switch is needed

      if Threads.Queues.Context_Switch_Needed then
         --  Perform a context switch because the currently executing thread
         --  is blocked or it is no longer the one with the highest priority.

         --  Update Execution Time before context switch

         if Scheduling_Event'Address /= System.Null_Address then
            Scheduling_Event (System.BB.Time.Clock);
         end if;

         CPU_Primitives.Context_Switch;
      end if;

      --  Now we need to set the hardware interrupt masking level equal to the
      --  software priority of the task that is executing.

      CPU_Primitives.Enable_Interrupts
        (Threads.Queues.Running_Thread.Active_Priority);
   end Leave_Kernel;

end System.BB.Protection;
