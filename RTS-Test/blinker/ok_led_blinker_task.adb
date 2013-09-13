with Interfaces;    use Interfaces;
with Ada.Real_Time; use Ada.Real_Time;

with Rpi.gpio;      use Rpi.gpio;
with Rpi.Registers; use Rpi.Registers;

package body Ok_Led_Blinker_task is

   ----------------
   -- OkLedBlink --
   ----------------


--     task body OkLedBlink is
--
--        OK_LED_Pin_No : Natural := 16;  --Connected to OK LED
--     begin
--        SetPinFunction (OK_LED_Pin_No, Output);
--        loop
--           DigitalWrite (OK_LED_Pin_No, Level_High); -- Ok LED will Be OFF
--
--           delay until Clock + Milliseconds (500);
--
--           DigitalWrite (OK_LED_Pin_No, Level_Low);  -- OK LED will be On
--
--           delay until Clock + Milliseconds (500);
--
--        end loop;
--     end OkLedBlink;


   protected body Epoch is
      procedure Get_Start_Time (T : out Ada.Real_Time.Time) is
      begin
	 if First then
	    First := False;
	    Start := Ada.Real_Time.Clock;
	 end if;
	 T := Start;
      end Get_Start_Time;
   end Epoch;


   task body TurnOnLed_Type  is
      Next_Period : Ada.Real_Time.Time;
      Period : constant Ada.Real_Time.Time_Span := Milliseconds(Cycle_Time_mS);
      OK_LED_Pin_No : Natural := 16;  --Connected to OK LED

   begin
      SetPinFunction (OK_LED_Pin_No, Output);
      Epoch.Get_Start_Time (Next_Period);
      Next_Period := Next_Period + Milliseconds (Offset_mS);

      loop
         delay until Next_Period;

	 DigitalWrite (OK_LED_Pin_No, Level_Low); -- Ok LED will Be On

	 Next_Period := Next_Period + Period;
      end loop;

   end TurnOnLed_Type;

   task body TurnOffLed_Type  is
      Next_Period : Ada.Real_Time.Time;
      Period : constant Ada.Real_Time.Time_Span := Milliseconds (Cycle_Time_mS);
      OK_LED_Pin_No : Natural := 16;  --Connected to OK LED

   begin
      SetPinFunction (OK_LED_Pin_No, Output);
      Epoch.Get_Start_Time (Next_Period);
      Next_Period := Next_Period + Milliseconds (Offset_mS);

      loop
         delay until Next_Period;

	 DigitalWrite (OK_LED_Pin_No, Level_High); -- Ok LED will Be OFF

	 Next_Period := Next_Period + Period;
      end loop;

   end TurnOffLed_Type;

   TurnOnLed : TurnOnLed_Type (System.Default_Priority, 1000, 0 ); -- mS
   TurnOffLed : TurnOffLed_Type (System.Default_Priority, 1000,500); -- in mS

end Ok_Led_Blinker_task;
