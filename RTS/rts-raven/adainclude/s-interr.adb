------------------------------------------------------------------------------
--                                                                          --
--                 GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                 --
--                                                                          --
--                     S Y S T E M . I N T E R R U P T S                    --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--                     Copyright (C) 2001-2010, AdaCore                     --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
------------------------------------------------------------------------------

--  This is a generic bare board version of this package

pragma Restrictions (No_Elaboration_Code);

package body System.Interrupts is

   ----------------
   -- Local Data --
   ----------------

   type Handlers_Table is array (Interrupt_ID) of Parameterless_Handler;
   pragma Suppress_Initialization (Handlers_Table);
   --  Type used to represent the procedures used as interrupt handlers

   User_Handlers : Handlers_Table;
   --  Table containing user handlers

   -----------------------
   -- Local Subprograms --
   -----------------------

   procedure Install_Handler
     (Interrupt : Interrupt_ID;
      Handler   : Parameterless_Handler);
   --  Install the runtime umbrella handler for a hardware interrupt

   procedure Default_Handler (Interrupt : System.OS_Interface.Interrupt_ID);
   --  Default interrupt handler

   ---------------------
   -- Default_Handler --
   ---------------------

   procedure Default_Handler
     (Interrupt : System.OS_Interface.Interrupt_ID)
   is separate;
   --  Depending on whether exception propagation is supported or not, the
   --  implementation will differ; exceptions can never be propagated through
   --  this procedure (see ARM C.3 par. 7).

   ---------------------
   -- Install_Handler --
   ---------------------

   procedure Install_Handler
     (Interrupt : Interrupt_ID;
      Handler   : Parameterless_Handler)
   is
   begin
      --  Copy the handler in the table that contains the user handlers

      User_Handlers (Interrupt) := Handler;

      --  Attach the default handler to the specified interrupt. This handler
      --  will in turn call the user handler.

      System.OS_Interface.Attach_Handler
        (Default_Handler'Access,
         System.OS_Interface.Interrupt_ID (Interrupt));
   end Install_Handler;

   ---------------------------------
   -- Install_Restricted_Handlers --
   ---------------------------------

   procedure Install_Restricted_Handlers (Handlers : Handler_Array) is
   begin
      for J in Handlers'Range loop
         Install_Handler (Handlers (J).Interrupt, Handlers (J).Handler);
      end loop;
   end Install_Restricted_Handlers;

end System.Interrupts;
