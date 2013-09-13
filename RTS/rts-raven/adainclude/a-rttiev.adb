------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--          A D A . R E A L _ T I M E . T I M I N G _ E V E N T S           --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--           Copyright (C) 2005-2011, Free Software Foundation, Inc.        --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
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
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;
with System.BB.Time;
with Ada.Tags;

package body Ada.Real_Time.Timing_Events is

   use Ada.Tags;

   function To_Real_Time is new Ada.Unchecked_Conversion
     (System.BB.Time.Time, Ada.Real_Time.Time);
   --  Function to change the view from System.BB.Time.Time (unsigned 64-bit)
   --  to Ada.Real_Time.Time (unsigned 64-bit).
   --
   --  Ada.Real_Time.Time and System.BB.Time.Time are the same type, but
   --  Ada.Real_Time.Time is private so we don't have visibility.

   function To_BB_Time is new Ada.Unchecked_Conversion
     (Ada.Real_Time.Time, System.BB.Time.Time);
   --  Function to change the view from Ada.Real_Time.Time (unsigned 64-bit) to
   --  System.BB.Time.Time (unsigned 64-bit).
   --
   --  Ada.Real_Time.Time and System.BB.Time.Time are the same type, but
   --  Ada.Real_Time.Time is private so we don't have visibility.

   package SBTE renames System.BB.Timing_Events;

   ---------------------
   -- Handler_Wrapper --
   ---------------------

   procedure Handler_Wrapper
     (Event : in out System.BB.Timing_Events.Timing_Event'Class)
   is
      Handler : Timing_Event_Handler;

   begin
      if Event'Tag /= Ada.Real_Time.Timing_Events.Timing_Event'Class'Tag then
         raise Program_Error;
      end if;

      Handler := Timing_Event (Event).Real_Handler;

      if Handler /= null then
         Timing_Event (Event).Real_Handler := null;
         Handler.all (Timing_Event (Event));
      end if;
   end Handler_Wrapper;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (Event   : in out Timing_Event;
      At_Time : Time;
      Handler : Timing_Event_Handler)
   is
      BB_Handler : System.BB.Timing_Events.Timing_Event_Handler;

   begin
      Event.Real_Handler := Handler;

      if Handler = null then
         BB_Handler := null;
      else
         BB_Handler := Handler_Wrapper'Access;
      end if;

      SBTE.Set_Handler (SBTE.Timing_Event (Event),
                        To_BB_Time (At_Time),
                        BB_Handler);
   end Set_Handler;

   ---------------------
   -- Current_Handler --
   ---------------------

   function Current_Handler
     (Event : Timing_Event) return Timing_Event_Handler
   is
   begin
      return Event.Real_Handler;
   end Current_Handler;

   --------------------
   -- Cancel_Handler --
   --------------------

   procedure Cancel_Handler
     (Event     : in out Timing_Event;
      Cancelled : out Boolean)
   is
   begin
      SBTE.Cancel_Handler (SBTE.Timing_Event (Event), Cancelled);
      Event.Real_Handler := null;
   end Cancel_Handler;

   -------------------
   -- Time_Of_Event --
   -------------------

   function Time_Of_Event (Event : Timing_Event) return Time is
   begin
      return To_Real_Time (SBTE.Time_Of_Event (SBTE.Timing_Event (Event)));
   end Time_Of_Event;

end Ada.Real_Time.Timing_Events;
