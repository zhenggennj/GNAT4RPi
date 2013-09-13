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
with System;
--with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Rpi.Registers; use Rpi.Registers;
with Rpi.gpio; use Rpi.gpio;

package body Rpi.Mini_uart is

   ---------------
   -- Uart_Init --
   ---------------

   procedure Uart_Init is
   begin
      AUX_ENABLES := 1;
      -- bit 0: mini_uart; bit 1: SPI 1; bit 2: SPI 2

      AUX_MU_IER_REG := 0;
      --  bit 0 for sending IRQ Enabling; bit 1 for receiving IRQ Enabling.

      AUX_MU_CNTL_REG := 0;
      --  bit 0: Receiver enable
      --  bit 1: Transmitter enable
      --  bit 2-3 : Enable flow ctrl using RTS and CTS
      --  bit 4-5 : RTS AUTO flow level
      --  bit 6-7:  RTS and CTS assert level

      AUX_MU_LCR_REG := 3;
      --  Line Ctrl Reg
      --  bit 1-0:  00: 7 bit mode; 11:8bit mode; Thanks to David Welch.
      --  bit 5-2: reserved
      --  bit 6  :  Break
      --  bit 7  :  DLAB access

      AUX_MU_MCR_REG := 0;
      --  Modem Ctrl Reg
      --  bit 0 and 31-2 : reserved
      --  bit 1 : RTS

      AUX_MU_IIR_REG := 16#0000_00C6#;
      --  bit 0: Interrupt Pending, read only
      --  bit 2-1:  When writing, bit 1 clears receive FIFO
      --            and bit 2 clears transmit FIFO.
      --  bit 5-3: read only
      --  bit 7-6:  FIFO enables. always 11 : Both FIFO are always enabled.
      --  bit 31-8: not care

      AUX_MU_BAUD_REG := 270;
      --  bit 15-0:  Baudrate.
      --  Baudrate=(system_clock_freq/8/(baudrate_reg + 1)
      --  baudrate_reg = 250M /8 / 115200 -1
      --  bit 31-16: not care

      SetPinFunction (14, alt_func5);
      SetPinFunction (15, alt_func5);
      --  pin 14 is for TXD0 and TXD1(mini uart)
      --  pin 15 is for RXD0 and RXD1(mini uart)

      GPPUD := 0;
      --  bit 1-0:  00 = disable pull-up/down
      --            01 = Enable Pull Down ctrl
      --            10 = Enable Pull Up ctrl
      --            11 = reserved
      --  bit 31-2: unused.

      DelayByLoop (150);
      GPPUDCLK (0) := 2 ** 14 or 2 ** 15;
      DelayByLoop (150);

      AUX_MU_CNTL_REG := 3;
      -- Enable both receiving and transmitting

   end Uart_Init;

   ---------------
   -- Uart_Send --
   ---------------

   procedure Uart_Send (AChar : Unsigned_8) is
   begin
      AUX_MU_IO_REG := Unsigned_32 (AChar);
   end Uart_Send;

   ----------------------
   -- Is_Ready_Sending --
   ----------------------

   function Is_Ready_Sending return boolean is
      Result : Boolean := false;
   begin
      if (Unsigned_8 (AUX_MU_LSR_REG) and 16#20#) = 16#20# then
         Result := True;
      end if;
      return Result;

   end Is_Ready_Sending;

   ---------------
   -- Uart_Recv --
   ---------------

   function Uart_Recv return Unsigned_8 is
   begin
      return Unsigned_8 (AUX_MU_IO_REG and 16#0000_00FF#);
   end Uart_Recv;

   ------------------------
   -- Is_Ready_Receiving --
   ------------------------

   function Is_Ready_Receiving return boolean is
      Result : Boolean := False;
   begin
      if (unsigned_8 (AUX_MU_LSR_REG) and 16#01#) = 1 then
         Result := True;
      end if;
      return Result;

   end Is_Ready_Receiving;

   ----------------
   -- Uart_Flush --
   ----------------

   procedure Uart_Flush is
   begin
      Loop
         exit when (unsigned_8 (AUX_MU_LSR_REG) and 16#40#) = 16#40# ;
      end loop;
   end Uart_Flush;

   protected Mini_UART_Out is
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
      pragma Priority (system.Priority'Last);
   end Mini_UART_Out;

   protected body Mini_UART_Out is

       --------------------------------
       --  Put (a_char : character)  --
       --------------------------------

       procedure Put (A_char : Unsigned_8;  Is_Success : out boolean) is
       begin
          Is_Success := False;
          for i in 1..200 loop
    	 --  the maximum time of  200 loop is about 89uS
             --  10 bits * (1/115200) is about 87uS
             --  maximum wait a period of transmitting one chanracter
             if Is_Ready_Sending  then
                Is_Success := True;
                exit;
             end if;
          end loop;
          if not Is_Success then
             SetLastError (Out_Buffer_Not_Ready);
             return;
          end if;
          Uart_Send (A_char);
       end put;

       -------------
       -- Hex_Put --
       -------------

       procedure Hex_Put (Val : Unsigned_32;  Is_Success : out boolean) is
          A_Digit, Val_Tmp : Unsigned_32 := Val;
          Shift_Count : Natural;

       begin
          Shift_Count := 32;

          loop
             Shift_Count := Shift_Count - 4;
             Val_Tmp := Shift_Right (Val, Shift_Count) ;
             A_Digit := Val_Tmp and 16#0000_000F#;
             if A_Digit > 9 then
                A_Digit := A_Digit + 16#0000_0037#;
             else
                A_Digit := A_Digit + 16#0000_0030#;
             end if;

             Is_Success := False;
    	 put (unsigned_8 (A_Digit), Is_Success);
    	 if not Is_Success then
    	    return;
    	 end if;

    	 exit when Shift_Count = 0;
          end loop;
    --      put (unsigned_8 (16#20#), Is_Success);

        end Hex_Put;

       ------------------
       -- New_Line     --
       ------------------

       procedure New_Line (Is_Success : out boolean) is
       begin
    	 Is_Success := False;
    	 put (unsigned_8 (16#0A#), Is_Success);
    	 put (unsigned_8 (16#0D#), Is_Success);

       end New_Line;

       ------------------
       -- Hex_Put_Line --
       ------------------

       procedure Hex_Put_Line (Val : Unsigned_32; Is_Success : out boolean) is

       begin
          Is_Success := False;
          Hex_Put (Val, Is_Success);
          New_Line (Is_Success);

       end Hex_Put_Line;

   end Mini_UART_Out;


   procedure Put (A_Char : unsigned_8;  Is_Success : out boolean) is
   begin
      Mini_UART_Out.Put (A_Char, Is_Success);
   end put;


   procedure Hex_Put (Val : Unsigned_32; Is_Success : out boolean) is
   begin
      Mini_UART_Out.Hex_Put (Val, Is_Success);
   end Hex_Put;

   procedure New_Line (Is_Success : out boolean) is
   begin
      Mini_UART_Out.New_Line (Is_Success);
   end New_Line;

   procedure Hex_Put_Line (Val : Unsigned_32; Is_Success : out boolean) is
   begin
      Mini_UART_Out.Hex_Put_Line (Val, Is_Success);

   end Hex_Put_Line;
      -- New_Line will be called after the Val in Hex is sent.
      --  Based on New_Line and Hex_Put.



   -------------------
   --  SetLastError --
   -------------------
   procedure SetLastError (An_Error : Error_Type) is
   begin
      Last_Error := An_Error;
   end SetLastError;

   --------------------
   --  GetLastError  --
   --------------------
   function GetLastError return Error_Type is
   begin
      return Last_Error;
   end GetLastError;
begin
   Uart_Init;

end Rpi.Mini_uart;
