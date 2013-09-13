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

package rpi.gpio is
   type GPIO_Pin_Type is
     (GPIO0, GPIO1, GPIO2, GPIO3, GPIO4, GPIO5, GPIO6, GPIO7, GPIO8, GPIO9,
      GPIO10,GPIO11,GPIO12,GPIO13,GPIO14,GPIO15,GPIO16,GPIO17,GPIO18,GPIO19,
      GPIO20,GPIO21,GPIO22,GPIO23,GPIO24,GPIO25,GPIO26,GPIO27,GPIO28,GPIO29,
      GPIO30,GPIO31,GPIO32,GPIO33,GPIO34,GPIO35,GPIO36,GPIO37,GPIO38,GPIO39,
      GPIO40,GPIO41,GPIO42,GPIO43,GPIO44,GPIO45,GPIO46,GPIO47,GPIO48,GPIO49,
      GPIO50,GPIO51,GPIO52,GPIO53 );

   type Level_type is (Level_Low, Level_High);
   for Level_type use (Level_Low => 0, Level_High => 1);

   type Pin_Function_Type is (
     Input,
     Output,
     Alt_func0,
     Alt_Func1,
     Alt_Func2,
     alt_func3,
     alt_func4,
     alt_func5);

   procedure SetPinFunction (Pin_No : in Natural; Func : in Pin_Function_Type);
   --Name: PinFunction
   --Function: Set up pin function according to given Pin_no and Func
   --enumeration
   --Input: Pin_No: the associated pin number
   --           Func: the function value from Pin_function type
   --Output:None
   --Description:
   --   There are totally 54 GPIO pins. Pin Function are defined in 6 32bit
   --registers GPFSEL0~GPFSEL5. Each pin occupies three bits. One register
   --holds ten 3_bit items. The 3_bit item coding is given in the
   --PinFunctionCodeArray.  The Register Address and the 3_bit item position
   --in a register have to be evaluated according to the given Pin Number. The
   --respective 3_bit in the register are cleared to zero and a certain pin
   --function code is masked into this register in the cleared area. The clear
   --and or operation are implemented using bitwise shift operation.

   procedure DigitalWrite (Pin_no : in Natural; Level : Level_type);
   --Name: DigitalWrite
   --Function: To Set the respective Pin to High or to Clear it to Low.
   --Input: Pin_No: the Number of the pin
   --         Level: a Value for Level_Type, Namely Level_lo or Level_High
   --Output:None
   --Description:
   --    To Set a Pin means to set a bit to 1 in the GPSET0 or GPSET1
   --register. The register is chosen according to the Pin Number. When Pin
   --Number is smaller than 32, GPSET0 is used. Otherwise, GPSET1 is used. The
   --bit position is the mod value of Pin Number relative to 32.
   --  To Clear a Pin works in the same way, only using GPCLR0 and GPCLR1
   --instead.

   function DigitalRead (Pin_No : in Natural) return Unsigned_32;
   --Name: DigitalRead
   --Function: Read state from the given Pin_No.
   --Input: Pin_No: pin number
   --Output: the pin status in a unsigned_32 number. Only zeroth-bit is valid.
   --It maybe 0 or 1.
   --Description:
   --    The status of a pin is stored in GPLEV0 and GPLEV1. The register
   --number and bit position in the register are determined using Pin_No. The
   --status is masked out and shift to the zero bit.

   function DigitalRead (Pin_No : in Natural) return Level_type;
   --Name:DigitalRead
   --Function:Read state from the given pin_no
   --Input: Pin_No: pin number
   --Output: a level value based on type Level_type.
   --Description:
   --    The returned value is obtained by comparing the resulted Unsigned_32
   --from calling the first version of this function with 0 or 1. No direct
   --type conversion is used.

   procedure DelayByLoop (LoopCount : in Unsigned_32);
   --Name: DelayByLoop
   --Function: Delay a certain time based on given LoopCount
   --Input: LoopCount: the upper bound of the loop
   --Output:none
   --description:
   --    The delay is based on a loop ranging in 1..LoopCount. The operation
   --of the loop is a call to the dummy function.

   --Put32:
   --Put a 32bit Value to a Named register;
   --Defined in vectors.s in Asm
   procedure Put32 (Reg_32 : in Unsigned_32; Val_32 : in Unsigned_32);
   pragma Import (Asm, Put32, "PUT32");

   --Get32:
   --Get a 32bit Value From a Named register;
   --Defined in vectors.s in Asm
   function Get32 (Reg_32 : in Unsigned_32) return Unsigned_32;
   pragma Import (Asm, Get32, "GET32");

private
   type Pin_Function_Code_Array is array (Pin_Function_Type) of Unsigned_32;
   PinFunctionCodeArray : constant Pin_Function_Code_Array :=
     (2#000#,
      2#001#,
      2#100#,
      2#101#,
      2#110#,
      2#111#,
      2#011#,
      2#010#);


   --dummy
   --a procedure with only one return statement;
   --Defined in vectors.s in Asm
   --
   procedure dummy (Reg_32 : in Unsigned_32);
   pragma Import (Asm, dummy, "dummy");

   GPFSEL0 : constant Unsigned_32 := 16#2020_0000#; --R/W,for GPIO00-GPIO09
   GPFSEL1 : constant Unsigned_32 := 16#2020_0004#; --R/W,for GPIO10-GPIO19
   GPFSEL2 : constant Unsigned_32 := 16#2020_0008#; --R/W,for GPIO20-GPIO29
   GPFSEL3 : constant Unsigned_32 := 16#2020_000C#; --R/W,for GPIO30-GPIO39
   GPFSEL4 : constant Unsigned_32 := 16#2020_0010#; --R/W,for GPIO40-GPIO49
   GPFSEL5 : constant Unsigned_32 := 16#2020_0014#; --R/W,for GPIO50-GPIO53

   GPSET0 : constant Unsigned_32 := 16#2020_001C#; --W, for GPIO0-GPIO31
   GPSET1 : constant Unsigned_32 := 16#2020_0020#; --W, for GPI32-GPIO53

   GPCLR0 : constant Unsigned_32 := 16#2020_0028#; --W, for GPIO00-GPIO31
   GPCLR1 : constant Unsigned_32 := 16#2020_002C#; --W, for GPIO32-GPIO53

   GPLEV0 : constant Unsigned_32 := 16#2020_0034#;--R, for GPIO00-GPIO31
   GPLEV1 : constant Unsigned_32 := 16#2020_0038#;--R, for GPIO32-GPIO53

end RPi.gpio;
