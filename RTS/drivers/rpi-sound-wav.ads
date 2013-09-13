------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                     Copyright (C) 2010-2011, AdaCore                     --
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

--  Based on the sound driver provided by the LeJOS project.

--  Expected usage is to declare a File object representing a wav file and
--  import it as follows:
--
--     Beep : NXT.Audio.Wav.File;
--     pragma Import (C, Beep, "beep_wav_start");
--
--  You can then play the file via procedure Play, where "My_Volume" is some
--  allowed volume value:
--
--     Play (Beep, My_Volume);
--
--  The wav file must be specified to the linker to satisfy the pragma Import.
--  The base name of the file must correspond to the first part of the name
--  used in the Import pragma. For the example above, the file name specified
--  to the linker would have a base name of "beep_wav". The file name extension
--  would not be ".wav" however, because the wav file must be converted to ELF
--  format and must have a specific symbol defined. To do the conversion you
--  can use the following in a makefile, or perform the indicated steps
--  manually. The conversion need only be done once. The resulting new file
--  will have an extension of ".owav" when using the steps below, but the
--  specific extension is not important as long as that same name is specified
--  to the linker.
--
--  arm-eabi-objcopy -I binary -O elf32-littlearm -B arm \
--    --redefine-sym _binary_hello_wav_start=hello_wav_start \
--    --redefine-sym _binary_hello_wav_end=hello_wav_end \
--    --redefine-sym _binary_hello_wav_size=hello_wav_size \
--    hello.wav hello.owav
--
--  Note how the symbols are altered. That is how the name string used in the
--  pragma Import is defined.

--  Modified by L. G. Zheng for Raspberry Pi
package Rpi.Sound.Wav is

   type File is limited private;
   --  A "wav" file.  Currently we support only 8-bit PCM data formats.

   type Wave_Info is record
      Input : System.Address;
      Input_Length : Unsigned_32;
      Volume : Volume_Type;
      Rate : SamplingRate_Type;
      Channel : Channel_Mode;
      Cur_Pos : Integer;
   end record;

   procedure Retrieve_Wave_Info (The_File : File; The_Wave_Info : in out Wave_Info);

   procedure Play (Cur_Wave_Info : in out Wave_Info);
   --This "Play" should be in a loop with a delay of 1mS , since it will
   --return when the FIFO is full. It can only play a mono-11025kHz wav file
   --  smoothly.
   --  producer : 16 words * 1kHz = 16k Sampling per Second;
   --  consumer : 11025 Sampling per Second for mono, 22050 Sampling per second
   --             for stereo.
   pragma Inline (Play);


   procedure DMA_Play (Cur_Wave_Info : in out Wave_Info);
   --  This "DMA_Play" use DMA to play. Since the Next ControlBlock is pointed
   --  to the current ControBlock, it will play repeatly.
   --  After the play is activated, it will continue automatically and no
   --  CPU intervation is necessary. Thus it should be placed out of a loop.

   Invalid_Format : exception;

private

   type File is limited null record;
   --  The type must be actually limited (or tagged) in the full view because
   --  it must be passed by reference for the sake of taking the address of
   --  parameters of the type when passed to subprograms.
   --
   --  A wav file is a contiguous region of memory that contains subregions
   --  referred to as "chunks". Each chunk is a descriptor that contains
   --  specific data. The size of these data, and thus the chunk itself, vary
   --  with the kind of chunk. Some kinds of chunk are mandatory, others are
   --  optional. In addition, the required order of the chunks is only
   --  partially defined. Therefore, we cannot easily define a single type that
   --  statically represents all the possible content of a wav file. Hence we
   --  declare a minimal chunk representation and use address arithmetic to
   --  access the chunks within a file.

   for File'Alignment use Unsigned_32'Alignment;
   --  We map the first chunk in a file to the address of the file itself. The
   --  alignment clause ensures the alignment of objects of type File will be
   --  sufficient for the mapped "chunk" objects.

end Rpi.Sound.Wav;
