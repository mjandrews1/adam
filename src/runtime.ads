-- Package: adam
-- File:    src/runtime.ads
-- Summary: MUMPS Runtime (Execution Engine) specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Parser;                 use Parser;

package Runtime is

   -- Runtime state
   type Runtime_State is private;

   -- Initialize runtime
   function Create_Runtime return Runtime_State;

   -- Execute a program (AST)
   procedure Execute (State : in out Runtime_State;
                      Prog  : AST_Node_Ptr);

   -- Execute a single line
   procedure Execute_Line (State : in out Runtime_State;
                           Line  : AST_Node_Ptr);

   -- Get last $TEST result
   function Get_Test_Result (State : Runtime_State) return Boolean;

   -- Get error code
   function Get_Error_Code (State : Runtime_State) return Integer;

   -- Get error message
   function Get_Error_Message (State : Runtime_State) return String;

   -- Check if runtime is halted
   function Is_Halted (State : Runtime_State) return Boolean;

private

   type Runtime_State is record
      Test_Result : Boolean;
      Error_Code  : Integer;
      Error_Msg   : Unbounded_String;
      Halted      : Boolean;
   end record;

end Runtime;
