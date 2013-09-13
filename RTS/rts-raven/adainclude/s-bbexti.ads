------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--              S Y S T E M . B B . E X E C U T I O N _ T I M E             --
--                                                                          --
--                                 S p e c                                  --
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

with Ada.Task_Identification;

with System.BB.Threads;
with System.BB.Time;
with System.BB.Interrupts;

package System.BB.Execution_Time is
   pragma Preelaborate;

   --  Procedures Disable_Execution_Time and Scheduling_Event must be imported
   --  as Weak_External. This way we can compute execution time only when users
   --  need it, i.e. when Ada.Execution_Time or Ada.Execution_Time.Interrupts
   --  are used.

   --  How to import and use Disable_Execution_Time and Scheduling_Event:

   --  procedure Scheduling_Event (Now : System.BB.Time.Time);
   --  pragma Import (Ada, Scheduling_Event, "__gnarl_scheduling_event");
   --  pragma Weak_External (Scheduling_Event);

   --  if Scheduling_Event'Address /= System.Null_Address then
   --     Scheduling_Event (System.BB.Time.Clock);
   --  end if;

   --  procedure Disable_Execution_Time;
   --  pragma Import (Ada, Disable_Execution_Time,
   --                   "__gnarl_disable_execution_time");
   --  pragma Weak_External (Disable_Execution_Time);

   --  if Disable_Execution_Time'Address /= System.Null_Address then
   --     Disable_Execution_Time;
   --  end if;

   procedure Disable_Execution_Time;
   pragma Export (Ada, Disable_Execution_Time,
                    "__gnarl_disable_execution_time");
   --  Disable the CPU clock of the current processor. The clock remains
   --  disabled until the next call to Scheduling_Event.

   function Global_Interrupt_Clock return System.BB.Time.Time;
   --  Sum of the interrupt clocks

   function Interrupt_Clock
     (Interrupt : System.BB.Interrupts.Interrupt_ID)
      return System.BB.Time.Time;
   pragma Inline (Interrupt_Clock);
   --  CPU Time spent to handle the given interrupt

   procedure Scheduling_Event (Now : System.BB.Time.Time);
   pragma Export (Ada, Scheduling_Event, "__gnarl_scheduling_event");
   --  Assign elapsed time to the executing Task/Interrupt and reset CPU clock.
   --  If the clock is disabled, the elapsed time is discarded and the clock
   --  re-enabled.
   --
   --  The Scheduling_Event procedure must be called at the end of an execution
   --  period:
   --
   --  When the run-time switch from a task to another task
   --                                a task to an interrupt
   --                                an interrupt to a task
   --                                an interrupt to another interrupt
   --  and before idle loop.

   function Thread_Clock
     (Th : System.BB.Threads.Thread_Id) return System.BB.Time.Time;
   pragma Inline (Thread_Clock);
   --  CPU Time spent in the given thread

end System.BB.Execution_Time;
