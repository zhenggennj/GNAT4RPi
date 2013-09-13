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
--  Modified by L. G. Zheng for Raspberry Pi
--  Based on DexBasic Project

with Interfaces; use Interfaces;
--  with Ada.Numerics.Elementary_Functions;
--  use Ada.Numerics.Elementary_Functions;
with Rpi.Registers; use Rpi.Registers;
with Rpi.gpio;      use Rpi.gpio;
with System.storage_elements; use system.storage_elements;
package body Rpi.sound is

   -----------------------
   --  Local Procedure  --
   -----------------------
   procedure ToFifo (Height : Unsigned_32);

   ----------------------------
   --  Local type and object --
   ----------------------------

   type PWM_Range_Type is array (Channel_Mode, SamplingRate_Type) of Unsigned_32;
   PWM_Range_Array : constant PWM_Range_Type :=
--     (Mono=>(ST11025=>16#488#, ST22050=>16#244#, ST44100=>16#122#),
     (Mono=>(ST11025=>16#244#, ST22050=>16#122#, ST44100=>16#091#),
      Stereo=>(ST11025=>16#244#, ST22050=>16#122#, ST44100=>16#091#));

   ---------------------
   --  Implementation --
   ---------------------
   procedure SetChannelMode (A_Mode : Channel_Mode) is
   begin
      Cur_Channel_Mode := A_Mode;
      SetUpPwm;
   end SetChannelMode;

   function GetChannelMode return Channel_Mode is
   begin
      return Cur_Channel_Mode;
   end GetChannelMode;

   procedure SetSamplingRate (A_SamplingRate : SamplingRate_Type) is
   begin
      Cur_Sampling_Rate := A_SamplingRate;
      SetUpPwm;
   end SetSamplingRate;

   function GetSamplingRate return SamplingRate_Type is
   begin
      return Cur_Sampling_Rate;
   end GetSamplingRate;

   procedure SetVolume (A_Volume : Volume_Type) is
   begin
      Cur_Volume := A_Volume;
   end SetVolume;

   function GetVolume return Volume_Type is
   begin
      return Cur_Volume;
   end GetVolume;

   --------------
   -- SetUpPwm --
   --------------

   procedure SetUpPwm  is
      A_Channel_Mode : Channel_Mode := GetChannelMode;
      A_Sampling_Rate : SamplingRate_Type := GetSamplingRate;
   begin

      SetPinFunction (40, Alt_func0);
      SetPinFunction (45, Alt_func0);
      --  Pin 40: pwm0; Pin 45: pwm1

      PWMCLK_CNTL := 16#5a00_0020#;
      --  PM_PASSWORD | BCM2835_PWMCLK_CNTL_KILL

      PWM_CONTROL := 0;

      PWMCLK_DIV := 16#5a00_3000#;

      --  PM_PASSWORD  |  (idiv<<12)

      PWMCLK_CNTL := 16#5a00_0011#;
      --  PM_PASSWORD | BCM2835_PWMCLK_CNTL_ENABLE |
      --  BCM2835_PWMCLK_CNTL_OSCILLATOR

      PWM_CONTROL := 16#40#;
      --  PWMCTL_CLRF
         PWM0_RANGE  := PWM_Range_Array (A_Channel_Mode, A_Sampling_Rate);
         --  16#122#;
         PWM1_RANGE  := PWM_Range_Array (A_Channel_Mode, A_Sampling_Rate);
         --  16#122#;
      if A_Channel_Mode = Stereo then
         PWM_CONTROL := 16#2161#;
         --  BCM2835_PWM1_USEFIFO | BCM2835_PWM1_ENABLE |
         --  BCM2835_PWM0_USEFIFO | BCM2835_PWM0_ENABLE | 1<<6(i.e.PWMCTL_CLRF);
      else
         PWM_CONTROL := 16#0061#;
      end if;
      --  BCM2835_PWM0_USEFIFO | BCM2835_PWM0_ENABLE | 1<<6(i.e.PWMCTL_CLRF);

   end SetUpPwm;

   ----------
   -- Tone --
   ----------

   procedure Tone (Tone_Duration : Unsigned_8) is
      Height   : Unsigned_32;
      High_Duration,Low_Duration : Unsigned_8 := Tone_Duration / 2;
   begin
      Height   := 16#0000_000F#;
      for index in 1..High_Duration loop
	 if GetChannelMode = Stereo then
	    ToFifo (Height);
	 end if;
         ToFifo (Height);
      end loop;

      Height   := 16#0000_0000#;
      for index in 1..Low_Duration loop
	 if GetChannelMode = Stereo then
	    ToFifo (Height);
	 end if;
         ToFifo (Height);

      end loop;

   end Tone;

   procedure ToFifo (Height : Unsigned_32) is
      Is_FIFO_Full : Boolean := False;
   begin
      loop
         Is_FIFO_Full :=
           ((PWM_FIFO_STATUS and 16#0000_0001#) = 16#0000_0001#);
         exit when not Is_FIFO_Full;
      end loop;
      PWM_FIFO_DATA := Height;
   end ToFifo;

   type Note_Freq_Type is array (Note_Type) of Natural;
   Note_Freq_Array : Note_Freq_Type :=
     (262,      294,      330,      349,      392,      440,      494,
      523,      578,      659,      698,      784,      880,      988,
      1046,      1175,      1318,      1397,      1568,      1760,      1976);


   Sine_Wave523_11025 : aliased constant  Waveform :=
     (0,      9,      28,      55,      90,      127,      164,
      199,      226,      245,      254,      251,      237,      213,      182,
      146,      108,      72,      41,      17,      3);
   for Sine_Wave523_11025'Alignment use 16;   --  16 bytes = 128 bits

   Sine_Wave523_22050 : aliased constant Waveform :=
     (0,      3,      9,      17,      28,      41,      55,      72,      90,
      108,      127,      146,      164,      182,      199,      213,      226,
      237,      245,      251,      254,      254,      251,      245,      237,
      226,      213,      199,      182,      164,      146,      127,      108,
      90,      72,      55,      41,      28,      17,      9,      3,      0);
   --  The waveform for signals generated by Play_Tone
   Sine_Wave523_44100 : aliased constant Waveform :=
     (0,      1,      3,      6,      9,      13,      17,      22,      28,
      34,      41,      48,      55,      63,      72,      81,      90,
      99,      108,      118,      127,      136,      146,      155,
      164,      173,      182,      190,      199,      206,      213,
      220,      226,      232,      237,      241,      245,      248,      251,
      253,      254,      254,      254,      253,      251,      248,      245,
      241,      237,      232,      226,      220,      213,      206,      199,
      191,      182,      173,      164,      155,      146,      136,      127,
      118,      108,      99,      90,      81,      72,      64,      55,
      48,      41,      34,      28,      22,      17,      13,      9,
      6,      3,      1,      0,   0);


   procedure Play (A_Note : Note_Type) is
      Cur_Sam : SamplingRate_Type := GetSamplingRate;
      Cur_Mode : Channel_Mode := GetChannelMode;
   begin
      case Cur_Sam is
         when ST11025 =>
            for Index in Sine_Wave523_11025'First .. Sine_Wave523_11025'Last
	    loop
	       if Cur_Mode = Stereo then
		  ToFifo (Unsigned_32 (Sine_Wave523_11025 (Index)));
	       end if;

               ToFifo (Unsigned_32 (Sine_Wave523_11025 (Index)));
            end loop;
         when ST22050 =>
            for Index in Sine_Wave523_22050'First .. Sine_Wave523_22050'Last
            loop
	       if Cur_Mode = Stereo then
                  ToFifo (Unsigned_32 (Sine_Wave523_22050 (Index))/2);
	       end if;
               ToFifo (Unsigned_32 (Sine_Wave523_22050 (Index))/2);
            end loop;
         when others =>
            for Index in Sine_Wave523_44100'First .. Sine_Wave523_44100'Last
            loop
	       if Cur_Mode = Stereo then
                  ToFifo (Unsigned_32 (Sine_Wave523_44100 (Index))/4);
	       end if;
               ToFifo (Unsigned_32 (Sine_Wave523_44100 (Index))/4);
            end loop;
      end case;
   end Play;


   procedure Play523_11025 ( Cur_Pos : in out integer) is
      Is_FIFO_Full : Boolean := False;
   begin
      if Cur_Pos < 0 then
	 Cur_Pos := Sine_Wave523_11025'First;
      end if;
      loop
         Is_FIFO_Full :=
           ((PWM_FIFO_STATUS and 16#0000_0001#) = 16#0000_0001#);
	 exit when Is_FIFO_Full;
	 if GetChannelMode = Stereo then
	    PWM_FIFO_DATA := Unsigned_32 (Sine_Wave523_11025 (Cur_Pos));
	 end if;

	 PWM_FIFO_DATA := Unsigned_32 (Sine_Wave523_11025 (Cur_Pos));
	 Cur_Pos := Cur_Pos +1;
	 if Cur_Pos > Sine_Wave523_11025'Last then
	    Cur_Pos := Sine_Wave523_11025'First;
	 end if;

      end loop;

   end Play523_11025;

   procedure Play523_22050 ( Cur_Pos : in out integer) is
      Is_FIFO_Full : Boolean := False;
   begin
      if Cur_Pos < 0 then
	 Cur_Pos := Sine_Wave523_22050'First;
      end if;
      loop
         Is_FIFO_Full :=
           ((PWM_FIFO_STATUS and 16#0000_0001#) = 16#0000_0001#);
	 exit when Is_FIFO_Full;
	 if GetChannelMode = Stereo then
	    PWM_FIFO_DATA := Unsigned_32 (Sine_Wave523_22050 (Cur_Pos))/2;
	 end if;

	 PWM_FIFO_DATA := Unsigned_32 (Sine_Wave523_22050 (Cur_Pos))/2;
	 Cur_Pos := Cur_Pos +1;
	 if Cur_Pos > Sine_Wave523_22050'Last then
	    Cur_Pos := Sine_Wave523_22050'First;
	 end if;

      end loop;

   end Play523_22050;

   procedure Play523_44100 ( Cur_Pos : in out integer) is
      Is_FIFO_Full : Boolean := False;
   begin
      if Cur_Pos < 0 then
	 Cur_Pos := Sine_Wave523_44100'First;
      end if;
      loop
         Is_FIFO_Full :=
           ((PWM_FIFO_STATUS and 16#0000_0001#) = 16#0000_0001#);
	 exit when Is_FIFO_Full;
	 if GetChannelMode = Stereo then
	    PWM_FIFO_DATA := Unsigned_32 (Sine_Wave523_44100 (Cur_Pos))/4;
	 end if;

	 PWM_FIFO_DATA := Unsigned_32 (Sine_Wave523_44100 (Cur_Pos))/4;
	 Cur_Pos := Cur_Pos +1;
	 if Cur_Pos > Sine_Wave523_44100'Last then
	    Cur_Pos := Sine_Wave523_44100'First;
	 end if;

      end loop;

   end Play523_44100;

--   DMA_CB0 , DMA_CB1, DMA_CB2,DMA_CB3 : DMA_CTRL_BLOCK;

   procedure PlayMono523_22050_DMA  is
      A_TI : Unsigned_32;
      A_Start_Index : natural;
      A_Fifo_ad : Unsigned_32;
   begin
      A_Start_Index := Sine_Wave523_22050'first;

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

      DMA_CB0.SOURCE_AD := unsigned_32 (To_Integer(
	Sine_Wave523_22050 (A_Start_Index)'address));
      DMA_CB0.DEST_AD := A_FiFo_ad;
      DMA_CB0.TXFR_LEN := Sine_Wave523_22050'Length*4;
      DMA_CB0.STRIDE := 0;
      DMA_CB0.NEXTCONBK := unsigned_32(To_Integer( DMA_CB0'Address));

      DMA_ENABLE := 16#0000_0001#;  -- channel 0 is enabled

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

   end PlayMono523_22050_DMA;
end rpi.sound;
