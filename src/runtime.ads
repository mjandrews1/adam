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

   -- Get current quit value
   function Get_Quit_Value (State : Runtime_State) return String;

   -- Set error trap ($ZTRAP)
   procedure Set_Error_Trap (State : in out Runtime_State; Label : String);

   -- Get error trap label
   function Get_Error_Trap (State : Runtime_State) return String;

   -- Raise a MUMPS error
   procedure Raise_Error (State : in out Runtime_State;
                          Code  : Integer;
                          Msg   : String);

private

   -- Label entry for DO/GOTO
   type Label_Entry is record
      Name    : Unbounded_String;
      Line_Ptr : AST_Node_Ptr;  -- Pointer to the line with this label
   end record;

   -- Label table (fixed size for simplicity)
   Max_Labels : constant Natural := 100;

   type Label_Array is array (1 .. Max_Labels) of Label_Entry;

   -- NEW scope entry
   type Scope_Entry is record
      Var_Name  : Unbounded_String;
      Old_Value : Unbounded_String;
   end record;

   Max_Scope_Depth : constant Natural := 100;
   type Scope_Array is array (1 .. Max_Scope_Depth) of Scope_Entry;

   type Runtime_State is record
      Test_Result   : Boolean;
      Error_Code    : Integer;
      Error_Msg     : Unbounded_String;
      Error_Trap    : Unbounded_String;  -- $ETRAP label
      Halted        : Boolean;
      Quit_Value    : Unbounded_String;  -- QUIT return value
      Skip_Remainder : Boolean;  -- Skip remaining commands on line (for ELSE)
      Jump_To       : AST_Node_Ptr;  -- For GOTO: jump to this line
      Labels        : Label_Array;
      Label_Count   : Natural;
      Scope_Stack   : Scope_Array;
      Scope_Top     : Natural;
   end record;

end Runtime;
