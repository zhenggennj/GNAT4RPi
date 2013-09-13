------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                    Copyright (C) 2010-2011, AdaCore                      --
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
-- Modified by L. G. Zheng for Raspberry Pi

with Interfaces; use Interfaces;

package Rpi.Mini_uart is

   procedure Uart_Init;
   --  Init the mini_uart
   --  Parameter:
   --  115200 bps, 8 data bit, no carity, 1 stop bit, no flow ctrl
   --  No IRQ is enabled.
   --  Check FIFO status before sending and receiving

   --------------------------
   --  Low-Level Send-Recv --
   --------------------------
   procedure Uart_Send (AChar : Unsigned_8);
   --  put a char into FILO
   --  pre_request: make a call to Is_Ready_Sending to see whether
   --               the FIFO Sending buf has free room for a char.

   function Is_Ready_Sending return boolean;
   --  Check the FiFo Sending buffer. If the buffer is full, it return false.
   --  else, it return true.
   --  Make a call to this function before sending anything.

   function Uart_Recv return Unsigned_8;
   --  return a char from FiFo recv buffer.
   --  pre_request: make a call to Is_Ready_Receiving to see whether
   --               the FIFO recv buf is not empty.

   function Is_Ready_Receiving return boolean;
   --  Check the FiFo Receiving buffer. If the buffer is empty, it return false.
   --  else, it return true.
   --  Make a call to this function before receiving anything.

   procedure Uart_Flush ;
   --  return until the FiFo sending buffer is empty.
   --  Call with caution. It may be blocked.

   ---------------------
   --  High level I/O --
   ---------------------
   type Error_Type is (No_Error, Out_Buffer_Not_Ready, In_Buffer_Not_Ready);
   subtype   string30 is string (1..30);
   type Error_Str_type is array (Error_Type) of string30;

   Error_str : Error_str_type :=
     (" No Error                     ",
      " Out Buffer is not ready.     ",
      " In buffer is not ready.      ");
   function GetLastError return Error_Type;

   procedure Put (A_Char : unsigned_8;  Is_Success : out boolean);
   --  A 200 times for loop will cause about 90uS delay.
   --  10 bits * (1/115200) is about 87uS.
   --  There is a safety gap between two successive characters

   procedure Hex_Put (Val : Unsigned_32; Is_Success : out boolean);
   --  send 8 digits (in Hex) through mini_uart.
   --  Based on put (A_char : unsigned_8 ...).

   procedure New_Line (Is_Success : out boolean);
   --  0x0D and 0x0A will be sent.
   --  Based on put (A_char : unsigned_8 ...).

   procedure Hex_Put_Line (Val : Unsigned_32; Is_Success : out boolean);
   -- New_Line will be called after the Val in Hex is sent.
   --  Based on New_Line and Hex_Put.

private
   Last_Error : Error_Type := No_Error;
   procedure SetLastError (An_Error : Error_Type);
end Rpi.Mini_uart;
