------------------------------------------------------------------------------
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
--                                                                          --
-- This  is  free  software;  you  can  redistribute  it and/or  modify  it --
-- under terms of the  GNU General Public License as published  by the Free --
-- Software  Foundation;  either version 2,  or (at your option)  any later --
-- version.  This  is  distributed  in the hope that  it  will  be  useful, --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANT- --
-- ABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General Public License distributed with GNATStack;  see file COPYING. If --
-- not, write to the  Free Software Foundation,  51 Franklin Street,  Fifth --
-- Floor, Boston, MA 02110-1301, USA.                                       --
------------------------------------------------------------------------------

with System; use System;
with Ada.Real_Time; use Ada.Real_Time;

generic
   type Message is private;
   Ceiling : Priority;
   Task_Priority : Priority;
   MIT : Time_Span;
   Stack_Size : Positive;
   with procedure Dispatch (Msg : Message);
package Sporadic_Archetype is

   procedure Wait (Msg : out Message; Release_Time : out Time);

   procedure Put (Msg : Message);

private

   protected Protocol is
      pragma Priority (Ceiling);

      entry Wait (Msg : out Message; Release_Time : out Time);

      procedure Put (Msg : Message);

   private

      Barrier    : Boolean := False;
      Stored_Msg : Message;

   end Protocol;

   task Handler is
      pragma Storage_Size (Stack_Size);
      pragma Priority (Task_Priority);
   end Handler;

end Sporadic_Archetype;
