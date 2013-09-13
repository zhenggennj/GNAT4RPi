------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                         S Y S T E M . B B . T I M E                      --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
--                     Copyright (C) 2003-2011, AdaCore                     --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
-- The porting of GNARL to bare board  targets was initially developed by   --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

--  Package in charge of implementing clock and timer functionalities
--  Modified for BCM2835 by L. G. Zheng.

with System.BB.Parameters;
with System.Multiprocessors;

package System.BB.Time is
   pragma Preelaborate;

   type Time is mod 2 ** 32;
   for Time'Size use 32;
   --  Time is represented at this level as a 32-bit natural number,
   --  representing the number of ticks.

   type Time_Span is range -2 ** 63 .. 2 ** 63 - 1;
   for Time_Span'Size use 64;
   --  Time_Span represents the length of time intervals, and it is defined as
   --  a 64-bit signed integer.

   ---------------
   -- Constants --
   ---------------

   Tick : constant Time := 1;
   --  A clock tick is a real time interval during which the clock value (as
   --  observed by calling the Clock function) remains constant. Tick is the
   --  average length of such intervals.

   Ticks_Per_Second : constant Natural := System.BB.Parameters.Clock_Frequency;
   --  Number of ticks (or clock interrupts) per second

   --------------------
   -- Initialization --
   --------------------

   procedure Initialize_Timers;
   --  Initialize this package (alarm handler). Must be called before any other
   --  functions.

   ----------------
   -- Operations --
   ----------------

   function Clock return Time;
   --  Get the number of ticks elapsed since startup

   procedure Delay_Until (T : Time);
   --  Suspend the calling thread until the absolute time specified by T

   function Get_Next_Timeout (CPU_Id : System.Multiprocessors.CPU) return Time;
   --  Get the date of the next alarm or timing event

   procedure Update_Alarm (Alarm : Time);
   --  Re-configure the timer if "Alarm" is earlier than the Pending_Alarm.
   --  Update_Alarm is the only routine allowed to set an alarm.

end System.BB.Time;
