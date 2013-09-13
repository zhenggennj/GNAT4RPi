with System; use System;
with Ada.Real_Time;

package Ok_Led_Blinker_task is
--     task  OkLedBlink  is
--        pragma Priority (Default_Priority);
--     end OkLedBlink;

   protected Epoch is
      procedure Get_Start_Time (T : out Ada.Real_Time.Time);
   private
      pragma Priority (System.Priority'Last);
      Start : Ada.Real_Time.Time;
      First : Boolean := True;
   end Epoch;

   task Type TurnOnLed_Type (A_Priority : System.Priority;
			     Cycle_Time_mS, Offset_mS : Natural) is
      pragma Priority (A_Priority);
   end TurnOnLed_Type;

   task Type TurnOffLed_Type (A_Priority : System.Priority;
			     Cycle_Time_mS, Offset_mS : Natural) is
      pragma Priority (A_Priority);
   end TurnOffLed_Type;

end Ok_Led_Blinker_task;

