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
with System;     use System;
with Rpi.Registers;    use Rpi.Registers;

package rpi.sound is
   type Channel_Mode is (Mono, Stereo);
   type SamplingRate_Type is (ST11025, ST22050, ST44100);
   for SamplingRate_Type use (ST11025=>11025, ST22050=>22050, ST44100=>44100);
   subtype Volume_Type is integer range -10 .. 10;
   -- Volume is the power to base 1.414.
   -- Volume factor := 1.414 ** A_Volume_Value.

   procedure SetChannelMode (A_Mode : Channel_Mode);
   --  Set Cur_Channel_Mode To A_Mode;
   --  Then call SetUpPwm;

   function GetChannelMode return Channel_Mode;
   pragma Inline (GetChannelMode);

   procedure SetSamplingRate (A_SamplingRate : SamplingRate_Type);
   --  Set Cur_Sampling_Rate to A_SamplingRate;
   --  Then call SetUpPwm;

   function GetSamplingRate return SamplingRate_Type;
   pragma Inline (GetSamplingRate);

   procedure SetVolume (A_Volume : Volume_Type);
   function GetVolume return Volume_Type;
   pragma Inline (GetVolume);

   procedure SetUpPwm ;
   --  Phone jack is connected to GPIO40 and GPIO45.
   --  Audio is fed through PWM interface.
   --  Using Current Parameters;

   procedure Tone (Tone_Duration : Unsigned_8);
   --  Play a Tone with duration Tone_Duration.
   --  Tone_duration := 22050Hz / Produced_Tone_Freq.
   --  Or Producted_Tone_Freq := 22050Hz / Tone_Duration.
   --  Period:  22050 /16  -> 1378 Hz
   --           22050 /42  ->  523 Hz (Do_M)
   --           22050 /500 ->   44 Hz

   type Note_Type is (Do_L, Re_L, Me_L, Fa_L, So_L, La_L, Xi_L,
		      Do_M, Re_M, Me_M, Fa_M, So_M, La_M, Xi_M,
		      Do_H, Re_H, Me_H, Fa_H, So_H, La_H, Xi_H);

   type Waveform is array (Natural range <>) of aliased Unsigned_32;

   procedure Play (A_Note : Note_Type);
   --  Play a Note.
   --  Only Do_M is implemented (with appropriate Sine_waveform)
   --  No Sine_Wavefor for other notes.

   procedure Play523_11025 ( Cur_Pos : in out integer);
   --  Play a 530Hz  tone with 11025Hz sampling rate.
   --  It returns whenever the FIFO is being filled full.
   --  The consuming rate in mono case is smaller than the producing rate.
   --  Cur_pos should be assigned a negative value in the first call
   --  indicationg the first call.

   procedure Play523_22050 ( Cur_Pos : in out integer);
   --  Play a 530Hz  tone with 22050Hz sampling rate.
   --  It returns whenever the FIFO is being filled full.
   --  The consuming rate in mono or stereo case is larger than
   --  the producing rate.
   --  The tone will be discontinuous.

   procedure Play523_44100 ( Cur_Pos : in out integer);
   --  Play a 530Hz  tone with 44100Hz sampling rate.
   --  It returns whenever the FIFO is being filled full.
   --  The consuming rate in mono or stereo case is larger than
   --  the producing rate.
   --  The tone will be discontinuous.

   DMA_CB0 : DMA_CTRL_BLOCK;

   procedure PlayMono523_22050_DMA;
   --  use DMA to transfer data from memory to PWM.
   --  Should not be placed in a loop. It will continue automatically.
private
   Cur_Channel_Mode : Channel_Mode := Stereo;
   Cur_Sampling_Rate : SamplingRate_Type := ST22050;
   Cur_Volume : Volume_Type := 0;

end RPi.sound;
