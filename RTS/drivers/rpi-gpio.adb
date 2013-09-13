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

package body rpi.gpio is

   procedure SetPinFunction (Pin_No : in Natural; Func : in Pin_Function_Type) is
      CurFuncSelRegAddr       : Unsigned_32;
      CurFuncSelRegAddrOffset : Unsigned_32;
      CurFuncSelRegIndex      : Natural;
      PosIndexInGPFSELn       : Natural;
      BitPosInGPFSELn         : Natural;
      RegValA, RegValB        : Unsigned_32;
   begin
      CurFuncSelRegIndex := Pin_No / 10;
      PosIndexInGPFSELn  := Pin_No mod 10;
      BitPosInGPFSELn    := 0;
      for i in 1 .. 3 loop
         BitPosInGPFSELn := BitPosInGPFSELn + PosIndexInGPFSELn;
      end loop;
      CurFuncSelRegAddrOffset := 0;
      for i in 1 .. 4 loop
         CurFuncSelRegAddrOffset := CurFuncSelRegAddrOffset +
                                    Unsigned_32 (CurFuncSelRegIndex);
      end loop;

      CurFuncSelRegAddr := GPFSEL0 + CurFuncSelRegAddrOffset;

      RegValA := Get32 (CurFuncSelRegAddr);
      --;10987654321098765432109876543210
      --ra&=~(7<<18);
      --;xxxxxxxxxxx000xxxxxxxxxxxxxxxxxx
      --;xxxxxxxxxxx001xxxxxxxxxxxxxxxxxx GPIO16
      RegValB := Shift_Left (7, BitPosInGPFSELn);
      RegValB := not RegValB;
      RegValA := RegValA and RegValB;
      --;          GPIO16
      --    ra|=1<<18;
      --as output
      RegValB := Shift_Left (PinFunctionCodeArray (Func), BitPosInGPFSELn);
      RegValA := RegValA or RegValB;
      Put32 (CurFuncSelRegAddr, RegValA);
   end SetPinFunction;

   procedure DigitalWrite (Pin_no : in Natural; Level : Level_type) is

   begin
      if Level = Level_High then
         if Pin_no < 32 then
            Put32 (GPSET0, Shift_Left (1, Pin_no));
         else
            Put32 (GPSET1, Shift_Left (1, (Pin_no mod 32)));
         end if;
      else
         if Pin_no < 32 then
            Put32 (GPCLR0, Shift_Left (1, Pin_no));
         else
            Put32 (GPCLR1, Shift_Left (1, (Pin_no mod 32)));
         end if;
      end if;

   end DigitalWrite;

   function DigitalRead (Pin_No : in Natural) return Unsigned_32 is
      Result, temp : Unsigned_32;
   begin
      if Pin_No < 32 then
         temp := Get32 (GPLEV0);
      else
         temp := Get32 (GPLEV1);
      end if;

      temp   := Shift_Right (temp, (Pin_No mod 32));
      Result := temp and 1;
      return Result;
   end DigitalRead;

   procedure DelayByLoop (LoopCount : in Unsigned_32) is
   begin
      for i in 1 .. LoopCount loop
         dummy (Unsigned_32 (i));
      end loop;

   end DelayByLoop;
   function DigitalRead (Pin_No : in Natural) return Level_type is
      Temp   : Unsigned_32 := DigitalRead (Pin_No);
      Result : Level_type  := Level_Low;
   begin
      if Temp = 1 then
         Result := Level_High;
      end if;
      return Result;

   end DigitalRead;

end rpi.gpio;
