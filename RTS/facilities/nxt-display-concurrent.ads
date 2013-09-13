------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------

--  High-level driver for LCD display. To be used if multiple tasks want
--  to write on the display.

with Ada.Real_Time; use Ada.Real_Time;
with Interfaces; use Interfaces;
with System; use System;

with System_Configuration; use System_Configuration;

with Simple_Cyclic_Archetype;

package Nxt.Display.Concurrent is

   procedure Clear;

   procedure Put (C : Character);
   procedure Put (S : String);
   procedure Put_Line (S : String);
   procedure Put_Timed (S : String);
   procedure Put (V : Integer);

   procedure Newline;

   procedure Put_Hex (Val : Unsigned_32);
   procedure Put_Hex (Val : Unsigned_16);
   procedure Put_Hex (Val : Unsigned_8);

   --  This can be modified to decrease/increase the frequency of updating the
   --  NXT display.
   Updater_Period : constant Time_Span := Milliseconds (500);
   Updater_Phase  : constant Time_Span := Milliseconds (0);

private

   protected Putter_Timed is
      pragma Priority (System.Priority'Last);

      procedure Put_Timed (S : String);

   end Putter_Timed;

   procedure Update_Screen;

   package Screen_Updater is new Simple_Cyclic_Archetype
     (Task_Priority => System.Priority'Last,
      Period => Updater_Period,
      Release_Time => System_Configuration.Release_Time,
      Phase => Updater_Phase,
      Stack_Size => 2048,
      Behaviour => Update_Screen);

end Nxt.Display.Concurrent;



