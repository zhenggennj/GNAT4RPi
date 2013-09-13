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

with System_Configuration; use System_Configuration;

package body Sporadic_Archetype is

   procedure Wait (Msg : out Message; Release_Time : out Time) is
   begin
      Protocol.Wait (Msg, Release_Time);
   end Wait;

   procedure Put (Msg : Message) is
   begin
      Protocol.Put (Msg);
   end Put;

   protected body Protocol is

      ----------
      -- Wait --
      ----------

      entry Wait (Msg : out Message; Release_Time : out Time)
        when Barrier is
      begin
         Release_Time := Clock;
         Msg          := Stored_Msg;
         Barrier      := False;
      end Wait;

      ---------
      -- Put --
      ---------

      procedure Put (Msg : Message) is
      begin
         Stored_Msg := Msg;
         Barrier    := True;
      end Put;

   end Protocol;

   task body Handler is
      Msg       : Message;
      Next_Time : Time := Release_Time;
   begin

      loop

         delay until Next_Time;

         Protocol.Wait (Msg, Next_Time);

         Dispatch (Msg);

         Next_Time := Next_Time + MIT;

      end loop;

   end Handler;

end Sporadic_Archetype;

