-- Package: adam
-- File:    src/runtime.adb
-- Summary: MUMPS Runtime (Execution Engine) implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with Parser;                 use Parser;
with Symbol_Table;
with Database;
with IO;
with String_Funcs;          use String_Funcs;
with Pattern;               use Pattern;

package body Runtime is

   function Create_Runtime return Runtime_State is
      State : Runtime_State;
   begin
      State.Test_Result := False;
      State.Error_Code := 0;
      State.Error_Msg := Null_Unbounded_String;
      State.Halted := False;
      return State;
   end Create_Runtime;

   -- Evaluate an expression node and return its string value
   function Eval_Expr (State : in out Runtime_State;
                       Node  : AST_Node_Ptr) return String is
   begin
      if Node = null then
         return "";
      end if;
      case Node.Kind is
         when N_String_Lit =>
            return To_String (Node.Value);
         when N_Number_Lit =>
            return To_String (Node.Value);
         when N_Variable =>
            declare
               Var_Name : constant String := To_String (Node.Value);
            begin
               if Var_Name'Length > 0 and then Var_Name (1) = '^' then
                  return To_String (Database.Get_Global (Var_Name (2 .. Var_Name'Last)));
               else
                  return To_String (Symbol_Table.Get_Var (Var_Name));
               end if;
            end;
         when N_Global =>
            return To_String (Database.Get_Global (To_String (Node.Value)));
         when others =>
            return "";
      end case;
   end Eval_Expr;

   -- Execute a SET command
   procedure Exec_Set (State : in out Runtime_State;
                       Node  : AST_Node_Ptr) is
      Var_Name : Unbounded_String;
      Value    : String (1 .. 1000);
      Val_Len  : Natural := 0;
   begin
      if Node.Left /= null and then Node.Left.Kind = N_Variable then
         Var_Name := Node.Left.Value;
         if Node.Right /= null then
            Value (1 .. Eval_Expr (State, Node.Right)'Length) :=
              Eval_Expr (State, Node.Right);
            Val_Len := Eval_Expr (State, Node.Right)'Length;
            Symbol_Table.Set_Var (To_String (Var_Name),
                                 Value (1 .. Val_Len));
         end if;
      end if;
   end Exec_Set;

   -- Execute a WRITE command
   procedure Exec_Write (State : in out Runtime_State;
                         Node  : AST_Node_Ptr) is
      Value : String (1 .. 1000);
      VLen  : Natural := 0;
   begin
      if Node.left /= null then
         Value (1 .. Eval_Expr (State, Node.left)'Length) :=
           Eval_Expr (State, Node.left);
         VLen := Eval_Expr (State, Node.left)'Length;
         IO.Write (Value (1 .. VLen));
      end if;
   end Exec_Write;

   -- Execute a single command node
   procedure Execute_Command (State : in out Runtime_State;
                              Node  : AST_Node_Ptr) is
   begin
      if Node = null or else State.Halted then
         return;
      end if;
      case Node.Kind is
         when N_Set =>
            Exec_Set (State, Node);
         when N_Write =>
            Exec_Write (State, Node);
         when N_Halt =>
            State.Halted := True;
         when N_Quit =>
            State.Halted := True;
         when N_If =>
            if Node.left /= null then
               declare
                  Cond : constant String := Eval_Expr (State, Node.left);
               begin
                  State.Test_Result := Cond /= "" and then Cond /= "0";
               end;
            end if;
         when N_Hang =>
            -- Simplified: just skip
            null;
         when others =>
            null;
      end case;
   end Execute_Command;

   -- Execute a single line
   procedure Execute_Line (State : in out Runtime_State;
                           Line  : AST_Node_Ptr) is
      Cmd : AST_Node_Ptr;
   begin
      if Line = null or else State.Halted then
         return;
      end if;
      -- Execute commands on this line
      Cmd := Line.left;
      while Cmd /= null and then not State.Halted loop
         Execute_Command (State, Cmd);
         Cmd := Cmd.Next;
      end loop;
   end Execute_Line;

   -- Execute a program (AST)
   procedure Execute (State : in out Runtime_State;
                      Prog  : AST_Node_Ptr) is
      Line : AST_Node_Ptr;
   begin
      if Prog = null or else Prog.Kind /= N_Program then
         return;
      end if;
      Line := Prog.left;
      while Line /= null and then not State.Halted loop
         Execute_Line (State, Line);
         Line := Line.Next;
      end loop;
   end Execute;

   function Get_Test_Result (State : Runtime_State) return Boolean is
   begin
      return State.Test_Result;
   end Get_Test_Result;

   function Get_Error_Code (State : Runtime_State) return Integer is
   begin
      return State.Error_Code;
   end Get_Error_Code;

   function Get_Error_Message (State : Runtime_State) return String is
   begin
      return To_String (State.Error_Msg);
   end Get_Error_Message;

   function Is_Halted (State : Runtime_State) return Boolean is
   begin
      return State.Halted;
   end Is_Halted;

end Runtime;
