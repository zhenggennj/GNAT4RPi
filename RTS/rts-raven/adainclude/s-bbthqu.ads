------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . T H R E A D S . Q U E U E S            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
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

with System.BB.Time;
with System.Multiprocessors;

package System.BB.Threads.Queues is
   pragma Preelaborate;

   ----------------
   -- Ready list --
   ----------------

   procedure Insert (Thread : Thread_Id);
   pragma Inline (Insert);
   --  Insert the thread into the ready queue. The thread is always
   --  inserted at the tail of its active priority because these are
   --  the semantics of FIFO_Within_Priorities dispatching policy when
   --  a task becomes ready to execute.

   procedure Extract (Thread : Thread_Id);
   pragma Inline (Extract);
   --  Remove the thread from the ready queue

   procedure Change_Priority
     (Thread   : Thread_Id;
      Priority : System.Any_Priority);
   pragma Inline (Change_Priority);
   --  Move the thread to a new priority within the ready queue

   function Current_Priority
     (CPU_Id : System.Multiprocessors.CPU) return System.Any_Priority;
   pragma Inline (Current_Priority);
   --  Return the active priority of the current thread or
   --  System.Any_Priority'First if no threads are running.

   procedure Yield (Thread : Thread_Id);
   --  Move the thread to the tail of its current priority

   Running_Thread_Table : array (System.Multiprocessors.CPU) of Thread_Id :=
                            (others => Null_Thread_Id);
   pragma Volatile_Components (Running_Thread_Table);
   pragma Export (Asm, Running_Thread_Table, "__gnat_running_thread_table");
   --  Identifier of the thread that is currently executing in the given CPU.
   --  This shared variable is used by the debugger to know which is the
   --  currently running thread. This variable is exported to be visible in the
   --  assembly code to allow its value to be used when necessary (by the
   --  low-level routines).

   First_Thread_Table : array (System.Multiprocessors.CPU) of Thread_Id :=
                          (others => Null_Thread_Id);
   pragma Volatile_Components (First_Thread_Table);
   pragma Export (Asm, First_Thread_Table, "first_thread_table");
   --  Pointers to the first thread of the priority queue for each CPU. This is
   --  the thread that will be next to execute in the given CPU (if not already
   --  executing). This variable is exported to be visible in the assembly code
   --  to allow its value to be used when necessary (by the low-level
   --  routines).

   function Running_Thread return Thread_Id;
   pragma Inline (Running_Thread);
   --  Returns the running thread of the current CPU

   function First_Thread return Thread_Id;
   pragma Inline (First_Thread);
   --  Returns the first thread in the priority queue of the current CPU

   function Context_Switch_Needed return Boolean;
   pragma Inline (Context_Switch_Needed);
   pragma Export (Asm, Context_Switch_Needed, "context_switch_needed");
   --  This function returns True if the task (or interrupt handler) that is
   --  executing is no longer the highest priority one. This function can also
   --  be called by the interrupt handlers' epilogue.

   ----------------
   -- Alarm list --
   ----------------

   procedure Insert_Alarm
     (T        : System.BB.Time.Time;
      Thread   : Thread_Id;
      Is_First : out Boolean);
   --  pragma Inline (Insert_Alarm);
   --  This function inserts the Thread inside the alarm queue ordered by
   --  Time. If the alarm is the next to be served then the functions
   --  returns true in the Is_First argument, and false if not.

   function Extract_First_Alarm return Thread_Id;
   pragma Inline (Extract_First_Alarm);
   --  Extract the first element in the alarm queue and return its
   --  identifier.

   function Get_Next_Alarm_Time
     (CPU_Id : System.Multiprocessors.CPU) return System.BB.Time.Time;
   pragma Inline (Get_Next_Alarm_Time);
   --  Return the time when the next alarm should be set. This function
   --  does not modify the queue.

   procedure Wakeup_Expired_Alarms;
   --  Wakeup all expired alarms and set the alarm timer if needed

   -----------------
   -- Global_List --
   -----------------

   Global_List : Thread_Id := Null_Thread_Id;
   --  This variable is the starting point of the list containing all threads
   --  in the system. No protection (for concurrent access) is needed for
   --  this variable because task creation is serialized.
   --  ??? Couldn't this be used to replace the static array of tasks which
   --  is used in System.Tasking.Debug?

end System.BB.Threads.Queues;
