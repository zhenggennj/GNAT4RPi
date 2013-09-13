package body Simple_Cyclic_Archetype is

   ------------
   -- Thread --
   ------------

   task body Thread is
      Next_Time : Time := Release_Time + Phase;
   begin
      loop
         delay until Next_Time;
         Behaviour;
         Next_Time := Next_Time + Period;
      end loop;
   end Thread;

end Simple_Cyclic_Archetype;
