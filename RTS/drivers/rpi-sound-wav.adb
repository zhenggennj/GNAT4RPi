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
--  Modified by L. G. Zheng for Raspberry Pi

with System;                   use System;
with System.Storage_Elements;  use System.Storage_Elements;
with Ada.Unchecked_Conversion;
with Rpi.gpio; use Rpi.gpio;

package body Rpi.Sound.Wav is

   subtype Identifier is String (1 .. 4);

   type Basic_Chunk is
      record
         Id   : Identifier;
         Size : Unsigned_32;
         Data : Unsigned_32;
      end record;
   --  Each chunk contains a four-character identifier (eg "data"), the size in
   --  bytes of the remaining data, and data of that size. We don't need to
   --  model the data itself because we just need to get the address of it, so
   --  we only declare a simple component for that purpose. The exception to
   --  that approach is the format chunk, where we need to access some of the
   --  actual components (eg the sample rate).

   type Basic_Chunk_Pointer is access all Basic_Chunk;
   for Basic_Chunk_Pointer'Storage_Size use 0;

   type Format_Chunk is
      record
         Id              : Identifier;
         Size            : Unsigned_32;
         Audio_Format    : Unsigned_16; -- 1 for PCM, others mean compression
         Num_Channels    : Unsigned_16;
         Sample_Rate     : Unsigned_32;
         Byte_Rate       : Unsigned_32;
         Block_Align     : Unsigned_16;
         Bits_Per_Sample : Unsigned_16; -- 8, 16, etc
      end record;

   Linear_PCM : constant := 1;  -- for audio format

   type Format_Chunk_Pointer is access all Format_Chunk;
   for Format_Chunk_Pointer'Storage_Size use 0;

   generic
      type Chunk is private;
      type Required_Chunk_Pointer is access all Chunk;
   function Chunk_Location (Name : Identifier; Within : File)
      return Required_Chunk_Pointer;
   --  Search the chunks in the file in memory, looking for the chunk with an
   --  Id matching Name.

   --------------------
   -- Chunk_Location --
   --------------------

   function Chunk_Location (Name : Identifier;  Within : File)
    return Required_Chunk_Pointer
   is
      Ptr         : Integer_Address;
      Max_Address : Integer_Address;

      Basic_Chunk_Size : constant Integer_Address := Basic_Chunk'Size / 8;
      --  the number of bytes required to represent a complete Basic_Chunk

      Size_of_Size_Field : constant := Unsigned_32'Size / 8;
      --  the number of bytes required to represent the size component within
      --  any kind of chunk

      function As_Chunk_Pointer is
        new Ada.Unchecked_Conversion (Integer_Address, Basic_Chunk_Pointer);

      function As_Required_Chunk_Pointer is
        new Ada.Unchecked_Conversion (Integer_Address, Required_Chunk_Pointer);

      function As_Identifier is
        new Ada.Unchecked_Conversion (Unsigned_32, Identifier);

   begin
      Ptr := To_Integer (Within'Address);

      if As_Chunk_Pointer (Ptr).Id /= "RIFF" then
         raise Invalid_Format;
      end if;
      if As_Identifier (As_Chunk_Pointer (Ptr).Data) /= "WAVE" then
         raise Invalid_Format;
      end if;

      if Name = As_Identifier (As_Chunk_Pointer (Ptr).Data) then
         return As_Required_Chunk_Pointer (Ptr);
      end if;

      Max_Address := To_Integer (Within'Address) +
        Integer_Address (As_Chunk_Pointer (Ptr).Size);
      --  The first chunk's size indicates the entire file size, rather than
      --  the chunk size, so it does not tell us where the next chunk is
      --  located. Instead we use it to bound our search, in case the named
      --  chunk is not found within the region of memory corresponding to the
      --  file.

      Ptr := Ptr + Basic_Chunk_Size;  --  Go to the second chunk

      while As_Chunk_Pointer (Ptr).Id /= Name loop
         declare
            This : Basic_Chunk renames As_Chunk_Pointer (Ptr).all;
         begin
            Ptr := To_Integer (This.Size'Address) +
                   Integer_Address (This.Size)    +
                   Size_of_Size_Field;
            if Ptr > Max_Address then
               return null;
            end if;
         end;
      end loop;

      return As_Required_Chunk_Pointer (Ptr);
   end Chunk_Location;

   -----------------
   -- Chunk_Named --
   -----------------

   function Chunk_Named is
     new Chunk_Location (Basic_Chunk, Basic_Chunk_Pointer);

   -----------------
   -- Chunk_Named --
   -----------------

   function Chunk_Named is
     new Chunk_Location (Format_Chunk, Format_Chunk_Pointer);


   --------------------------
   --  Retrieve_Wave_Info  --
   --------------------------

   procedure Retrieve_Wave_Info (The_File : File; The_Wave_Info : in out Wave_Info)
   is
      Format : constant Format_Chunk_Pointer := Chunk_Named ("fmt ", The_File);
      Sound  : constant Basic_Chunk_Pointer := Chunk_Named ("data", The_File);
   begin
      if Format.Audio_Format /= Linear_PCM then
         raise Invalid_Format;
      end if;
      The_Wave_Info.Input := Sound.Data'Address;
      The_Wave_Info.Input_Length := Sound.Size;
      case Format.Sample_Rate is
      when 11025 =>
	 The_Wave_Info.Rate := ST11025;
      when 22050 =>
	 The_Wave_Info.Rate := ST22050;
      when others=>
	 The_Wave_Info.Rate := ST44100;
      end case;
      if Format.Num_Channels = 1 then
	 The_Wave_Info.Channel := Mono;
      else
	 The_Wave_Info.Channel := Stereo;
      end if;


   end Retrieve_Wave_Info;

   ----------
   -- Play --
   ----------

   function To_Unsigned_32 is
     new Ada.Unchecked_Conversion (System.Address, Unsigned_32);

   procedure Play (Cur_Wave_Info : in out Wave_Info) is
      Is_FIFO_Full : Boolean := False;
      A_Data : Unsigned_32;
   begin
      if Cur_Wave_Info.Cur_Pos < 0 then
	 Cur_Wave_Info.Cur_Pos := 0;
      end if;
      loop
         Is_FIFO_Full :=
           ((PWM_FIFO_STATUS and 16#0000_0001#) = 16#0000_0001#);
	 exit when Is_FIFO_Full;
	 A_Data := Get32 (To_Unsigned_32 (Cur_Wave_Info.Input) +
		     Unsigned_32(Cur_Wave_Info.Cur_Pos));
	 A_Data := A_Data and 16#0000_00FF#;
	 if GetChannelMode = Stereo then
	    PWM_FIFO_DATA := A_Data;
	 end if;

	 PWM_FIFO_DATA := A_Data;
	 Cur_Wave_Info.Cur_Pos := Cur_Wave_Info.Cur_Pos +1;

	 if Cur_Wave_Info.Cur_Pos = integer (Cur_Wave_Info.Input_Length) then
	    Cur_Wave_Info.Cur_Pos := 0;
	 end if;

      end loop;


   end Play;

   ----------------
   --  DMA_PLAY  --
   ----------------
   Sample_Array_32bit : aliased WaveForm (1..22 * 1024 * 1024);

   procedure DMA_Play (Cur_Wave_Info : in out Wave_Info)  is
      A_TI : Unsigned_32;
      A_Fifo_ad : Unsigned_32;
      Ptr_32,data_32 : Unsigned_32;

   begin

      Ptr_32 :=  To_Unsigned_32 (Cur_Wave_Info.Input);
      for i in 1 .. Natural(Cur_Wave_Info.Input_Length) loop
	 data_32 := Get32 (Ptr_32 + unsigned_32(i-1));
	 Sample_Array_32bit(i) := data_32 and 16#0000_00FF#;
      end loop;

      A_FiFo_ad := 16#5E00_0000# +
	unsigned_32 (To_Integer (PWM_FIFO_DATA'Address));

      A_TI := 2#0000_0000_0000_0101_0000_0001_0100_0000#;
      --        3    2    2    1    1    1    7    3
      --        1    7    3    9    5    1
      --  bit31:27 reserved
      --  bit26   No_WIDE_BURSTS 0 (1= No use of Wide_bursts)
      --  bit25:21  WAITS        0 (0= no wait between each read or write
      --                           operation, 11111 : 31 cycles waiting)
      --  bit20:16  PERMAP   Peripheral Mapping, 00101 = 5 =PWM
      --  bit15:12:BURST_LENTH 0 (0= single transfer)
      --  bit11: SRC_IGNORE,  0( 0 = do perform source reads; 1=no read)
      --  bit10: SRC_DREQ,    0 (0 = DREQ will not control src reads.)
      --  bit9 : SRC_Width,   0 (0 = 32bits , 1=128bits)
      --  bit8 : SRC_INC ,    1 (1 = inc   ;0=no inc)
      --  bit7 : DEST_IGNORE, 0 (0 = Write data to destination. 1 = no write)
      --  bit6 : DEST_DREQ,  1 (1 = PWM DREQ control Destination writes)
      --  bit5 : DEST_WIDTH, 0 (0 = 32bit, 1= 128bit)
      --  bit4 : DEST_INC,  0 (0 = no inc)
      --  bit3 : WAIT_RESP, 0 (1 = wait ; 0= no wait)
      --  bit2 : reserved
      --  bit1 : TDMODE , 0 (0 = no 2D mode; 1 = 2Dmode)
      --  bit0 : INTEN , 0 (0 = no interrupt ; 1 = generate interrupt);
      DMA_CB0.TI := A_TI;

      DMA_CB0.SOURCE_AD :=
	To_Unsigned_32 (Sample_Array_32bit (Sample_Array_32bit'First)'Address);
      DMA_CB0.DEST_AD := A_FiFo_ad;
      DMA_CB0.TXFR_LEN := Cur_Wave_Info.Input_Length * 4;
      DMA_CB0.STRIDE := 0;
      DMA_CB0.NEXTCONBK := unsigned_32(To_Integer( DMA_CB0'Address));

      DMA_ENABLE := 16#0000_0001#;
      -- channel 0 is enabled
      -- Note DMA_CH5 won't work.

      PWM_DMAC := 16#8000_0001#;
      --  bit31     : ENAB   DMA ENable  1=Enable
      --  bit30:16  : reserved
      --  bit15:8   :  PANIC DMA Threshold for PANIC signal
      --  bit7:0    : DREQ  DMA threshold for DREQ signal

      DMA_CH0_CONBLK_AD := unsigned_32(To_Integer( DMA_CB0'Address));
      DMA_CH0_CS := 16#0000_0001#;

      --  DMA_CH5_CS := 2#1100_0000_0000_0000_0000_0000_0000_0110#;
      --  bit 31 : RESET    write 1=Reset the channel.
      --  bit 30 : ABORT    write 1=Abort Current DMA CB
      --  bit29  : DISDEBUG   write 1= not stop when debug pause
      --                               signal is asserted
      --  bit28  : WAIT_FOR_OUTSTANDING_WRITES  write, 1=wait
      --  bit27:24 : reserved
      --  bit23:20 : PANIC_PRIORITY : write, zero = lowest priority
      --  bit19:16 : PRIORITY   write: zero = lowest priority.
      --  bit15:9  reserved
      --  bit8  : ERROR    Read : 1=DMA channel has an error flag set
      --  bit7  : reserved
      --  bit6  : WAITING_FOR_OUTStAND_WRITES, REad : 1 = waiting
      --  bit5  : DREQ_STOPS_DMA :  Read: 1=Pause
      --  bit4  : PAUSED   Read : 1=DMA channel is paused. 0=running
      --  bit3  : DREQ     Read : DREQ state
      --                        (1=requesting data, 0=no data request)
      --  bit2  : INT      Read : Interrupt Status; write 1 to clear
      --  bit1  : END      Read : DMA End Flag; write 1 to clear
      --  bit0  : ACTIVE   write : 1 = enable

   end DMA_Play;
end Rpi.Sound.Wav;
