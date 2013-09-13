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

package body Nxt.Display.Concurrent is

   ------------------
   -- Putter_Timed --
   ------------------

   protected body Putter_Timed is

      ---------------
      -- Put_Timed --
      ---------------

      procedure Put_Timed (S : String) is
         Now : Integer := Integer (To_Duration (Clock - Release_Time));
      begin
         NXT.Display.Concurrent.Put ('[');
         NXT.Display.Concurrent.Put (Integer (Now));
         NXT.Display.Concurrent.Put_Line ("] : " & S);
      end Put_Timed;

   end Putter_Timed;

   -----------
   -- Clear --
   -----------

   procedure Clear renames Nxt.Display.Clear_Screen_Noupdate;

   ---------
   -- Put --
   ---------

   procedure Put (C : Character) renames Nxt.Display.Put_Noupdate;

   ---------
   -- Put --
   ---------

   procedure Put (S : String) renames Nxt.Display.Put_Noupdate;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (S : String) is
   begin
      Nxt.Display.Put_Noupdate (S);
      Nxt.Display.Newline_Noupdate;
   end Put_Line;

   ---------------
   -- Put_Timed --
   ---------------

   procedure Put_Timed (S : String) is
   begin
      Putter_Timed.Put_Timed (S);
   end Put_Timed;

   ---------
   -- Put --
   ---------

   procedure Put (V : Integer) renames Nxt.Display.Put_Noupdate;

   -------------
   -- Newline --
   -------------

   procedure Newline renames Nxt.Display.Newline_Noupdate;

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Val : Unsigned_32) renames Nxt.Display.Put_Hex;

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Val : Unsigned_16) renames Nxt.Display.Put_Hex;

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Val : Unsigned_8) renames Nxt.Display.Put_Hex;

   -------------------
   -- Update_Screen --
   -------------------

   procedure Update_Screen is
   begin
      Nxt.Display.Screen_Update;
   end Update_Screen;

end Nxt.Display.Concurrent;
