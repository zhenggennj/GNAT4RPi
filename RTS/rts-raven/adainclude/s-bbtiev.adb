------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                S Y S T E M . B B . T I M I N G _ E V E N T S             --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--                        Copyright (C) 2011, AdaCore                       --
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

with System.BB.CPU_Primitives.Multiprocessors;
with System.BB.Parameters;
with System.BB.Protection;

package body System.BB.Timing_Events is

   use type System.BB.Time.Time;
   use System.Multiprocessors;
   use System.BB.CPU_Primitives.Multiprocessors;

   Events_Table : array (CPU) of Timing_Event_Access :=
                    (others => null);
   --  One event list for each CPU

   procedure Insert (Event    : Timing_Event_Access;
                     Is_First : out Boolean);
   --  Insert an event in the event list of the current CPU (Timeout order
   --  then FIFO).

   procedure Extract (Event     : Timing_Event_Access;
                      Was_First : out Boolean);
   --  Extract an event from the event list of the current CPU

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (Event   : in out Timing_Event;
      At_Time : System.BB.Time.Time;
      Handler : Timing_Event_Handler)
   is
      Next_Alarm : System.BB.Time.Time := System.BB.Time.Time'Last;
      CPU_Id     : constant CPU        := Current_CPU;
      Was_First  : Boolean             := False;
      Is_First   : Boolean             := False;

   begin
      --  The access to the list must be protected

      Protection.Enter_Kernel;

      if Event.Handler /= null then

         --  Extract if the event is already set

         Extract (Event'Unchecked_Access, Was_First);
      end if;

      if Handler /= null then

         --  Update event fields

         Event.Timeout := At_Time;
         Event.Handler := Handler;
         Event.CPU     := CPU_Id;

         --  Insert event in the list

         Insert (Event'Unchecked_Access, Is_First);
      end if;

      if Was_First or else Is_First then
         --  Set the timer for the next alarm

         Next_Alarm := Time.Get_Next_Timeout (CPU_Id);
         Time.Update_Alarm (Next_Alarm);
      end if;

      Protection.Leave_Kernel;
   end Set_Handler;

   ---------------------
   -- Current_Handler --
   ---------------------

   function Current_Handler
     (Event : Timing_Event) return Timing_Event_Handler
   is
   begin
      return Event.Handler;
   end Current_Handler;

   --------------------
   -- Cancel_Handler --
   --------------------

   procedure Cancel_Handler
     (Event     : in out Timing_Event;
      Cancelled : out Boolean)
   is
      Next_Alarm : System.BB.Time.Time := System.BB.Time.Time'Last;
      CPU_Id     : constant CPU        := Current_CPU;
      Was_First  : Boolean             := False;

   begin
      --  The access to the list must be protected

      Protection.Enter_Kernel;

      if Event.Handler /= null then

         --  Extract if the event is already set

         Extract (Event'Unchecked_Access, Was_First);

         Cancelled     := True;
         Event.Handler := null;

         if Was_First then
            Next_Alarm := Time.Get_Next_Timeout (CPU_Id);
            Time.Update_Alarm (Next_Alarm);
         end if;
      else
         Cancelled := False;
      end if;

      Protection.Leave_Kernel;
   end Cancel_Handler;

   -----------------------------------
   -- Execute_Expired_Timing_Events --
   -----------------------------------

   procedure Execute_Expired_Timing_Events (Now : System.BB.Time.Time) is
      Event     : Timing_Event_Access;
      Handler   : Timing_Event_Handler;
      CPU_Id    : constant CPU := Current_CPU;
      Was_First : Boolean      := False;

   begin
      --  Extract and execute all the expired timing events

      loop
         Event := Events_Table (CPU_Id);

         --  Exit if there is no other expired events

         exit when Event = null
           or else Event.all.Timeout > Now;

         --  Extract events from the list

         Extract (Event, Was_First);

         Handler := Event.all.Handler;

         if Handler /= null then

            --  Clear the event

            Event.all.Handler := null;

            --  Execute the handler

            Handler (Event.all);
         end if;
      end loop;
   end Execute_Expired_Timing_Events;

   ----------------------
   -- Get_Next_Timeout --
   ----------------------

   function Get_Next_Timeout
     (CPU_Id : System.Multiprocessors.CPU) return System.BB.Time.Time
   is
      Event : constant Timing_Event_Access := Events_Table (CPU_Id);
   begin
      if Event = null then
         return System.BB.Time.Time'Last;
      else
         return Event.all.Timeout;
      end if;
   end Get_Next_Timeout;

   -------------------
   -- Time_Of_Event --
   -------------------

   function Time_Of_Event (Event : Timing_Event) return System.BB.Time.Time is
   begin
      if Event.Handler = null then
         return System.BB.Time.Time'First;
      else
         return Event.Timeout;
      end if;
   end Time_Of_Event;

   -------------
   -- Extract --
   -------------

   procedure Extract (Event     : Timing_Event_Access;
                      Was_First : out Boolean)
   is
      CPU_Id : constant CPU := Current_CPU;

   begin
      if System.BB.Parameters.Multiprocessor and then Event.CPU /= CPU_Id then

         --  Timing Events must always be handled by the same CPU

         raise Program_Error;
      end if;

      --  Middle or tail extraction

      if Event.Prev /= null then

         Was_First := False;
         Event.Prev.Next := Event.Next;

      --  Head extraction

      else
         Was_First := True;
         Events_Table (CPU_Id) := Event.Next;
      end if;

      if Event.Next /= null then
         Event.Next.Prev := Event.Prev;
      end if;

      Event.Next := null;
      Event.Prev := null;
   end Extract;

   -------------
   -- Insert --
   -------------

   procedure Insert
     (Event    : Timing_Event_Access;
      Is_First : out Boolean)
   is
      CPU_Id      : constant CPU := Current_CPU;
      Aux_Pointer : Timing_Event_Access;

   begin
      --  The event should be set

      pragma Assert (Event.Handler /= null);

      --  The event should not be inserted in a list

      pragma Assert (Event.Next = null and then Event.Prev = null);

      if System.BB.Parameters.Multiprocessor and then Event.CPU /= CPU_Id then

         --  Timing Events must always be handled by the same CPU

         raise Program_Error;
      end if;

      --  Insert at the head if there is no other events with a smaller timeout

      if Events_Table (CPU_Id) = null
        or else Events_Table (CPU_Id).Timeout > Event.Timeout
      then
         pragma Assert (Events_Table (CPU_Id) = null
                         or else Events_Table (CPU_Id).Prev = null);

         Is_First := True;

         Event.Next := Events_Table (CPU_Id);

         if Events_Table (CPU_Id) /= null then
            Events_Table (CPU_Id).Prev := Event;
         end if;

         Events_Table (CPU_Id) := Event;

      --  Middle or tail insertion

      else
         pragma Assert (Events_Table (CPU_Id) /= null);

         Is_First := False;

         Aux_Pointer := Events_Table (CPU_Id);
         while Aux_Pointer.Next /= null
           and then Aux_Pointer.Next.Timeout <= Event.Timeout
         loop
            Aux_Pointer := Aux_Pointer.Next;
         end loop;

         --  Insert after the Aux_Pointer

         Event.Next := Aux_Pointer.Next;
         Event.Prev := Aux_Pointer;

         if Aux_Pointer.Next /= null then
            Aux_Pointer.Next.Prev := Event;
         end if;

         Aux_Pointer.Next := Event;
      end if;
   end Insert;

end System.BB.Timing_Events;
