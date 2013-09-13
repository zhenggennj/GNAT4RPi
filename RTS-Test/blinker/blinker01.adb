with Interfaces;               use Interfaces;
with Ada.Real_Time;            use Ada.Real_Time;
with Ada.Unchecked_Conversion;

with Rpi.Mini_uart; use Rpi.Mini_uart;
with Ok_Led_Blinker_task;
with memory_compare;
pragma Partition_Elaboration_Policy (serialize);
procedure blinker01 is
   Counter : Unsigned_32;
   Is_Success : boolean;
begin

   Counter := 0;

   loop

      delay until Clock + Milliseconds (1000);

      Hex_Put_Line (Counter, Is_Success);
      Counter := Counter + 1;

   end loop;

end blinker01;
