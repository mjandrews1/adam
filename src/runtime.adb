-- Package: adam
-- File:    src/runtime.adb
-- Summary: MUMPS Runtime (Execution Engine) implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Float_Random;
with Parser;                 use Parser;
with Symbol_Table;
with Database;
with IO;
with String_Funcs;          use String_Funcs;
with Pattern;               use Pattern;

package body Runtime is

   -- Random number generator
   Gen : Ada.Numerics.Float_Random.Generator;

   function Create_Runtime return Runtime_State is
      State : Runtime_State;
   begin
      State.Test_Result := False;
      State.Error_Code := 0;
      State.Error_Msg := Null_Unbounded_String;
      State.Halted := False;
      State.Quit_Value := Null_Unbounded_String;
      State.Skip_Remainder := False;
      State.Label_Count := 0;
      State.Scope_Top := 0;
      Ada.Numerics.Float_Random.Reset (Gen);
      return State;
   end Create_Runtime;

   -- Convert string to float (returns 0.0 on error)
   function To_Float (Str : String) return Float is
      Result : Float := 0.0;
   begin
      if Str'Length > 0 then
         begin
            Result := Float'Value (Str);
         exception
            when others =>
               Result := 0.0;
         end;
      end if;
      return Result;
   end To_Float;

   -- Convert float to string (clean format)
   function From_Float (Val : Float) return String is
      Int_Val : Integer;
   begin
      Int_Val := Integer (Val);
      if Float (Int_Val) = Val then
         declare
            Int_Str : constant String := Integer'Image (Int_Val);
         begin
            if Int_Str (Int_Str'First) = ' ' then
               return Int_Str (Int_Str'First + 1 .. Int_Str'Last);
            end if;
            return Int_Str;
         end;
      end if;
      declare
         Str : constant String := Float'Image (Val);
      begin
         if Str (Str'First) = ' ' then
            return Str (Str'First + 1 .. Str'Last);
         end if;
         return Str;
      end;
   end From_Float;

   -- Add a label to the label table
   procedure Add_Label (State : in out Runtime_State;
                        Name  : String;
                        Line  : AST_Node_Ptr) is
   begin
      if State.Label_Count < Max_Labels then
         State.Label_Count := State.Label_Count + 1;
         State.Labels (State.Label_Count).Name := To_Unbounded_String (Name);
         State.Labels (State.Label_Count).Line_Ptr := Line;
      end if;
   end Add_Label;

   -- Find a label by name
   function Find_Label (State : Runtime_State;
                        Name  : String) return AST_Node_Ptr is
   begin
      for I in 1 .. State.Label_Count loop
         if To_String (State.Labels (I).Name) = Name then
            return State.Labels (I).Line_Ptr;
         end if;
      end loop;
      return null;
   end Find_Label;

   -- Push a variable scope (NEW)
   procedure Push_Scope (State    : in out Runtime_State;
                         Var_Name : String) is
   begin
      if State.Scope_Top < Max_Scope_Depth then
         State.Scope_Top := State.Scope_Top + 1;
         State.Scope_Stack (State.Scope_Top).Var_Name :=
           To_Unbounded_String (Var_Name);
         State.Scope_Stack (State.Scope_Top).Old_Value :=
           Symbol_Table.Get_Var (Var_Name);
         -- Clear the variable (MUMPS NEW creates undefined variable)
         Symbol_Table.Set_Var (Var_Name, "");
      end if;
   end Push_Scope;

   -- Pop variable scope (QUIT restores)
   procedure Pop_Scope (State : in out Runtime_State) is
   begin
      if State.Scope_Top > 0 then
         -- Restore the variable to its old value
         declare
            Var_Name : constant String :=
              To_String (State.Scope_Stack (State.Scope_Top).Var_Name);
            Old_Val  : constant String :=
              To_String (State.Scope_Stack (State.Scope_Top).Old_Value);
         begin
            Symbol_Table.Set_Var (Var_Name, Old_Val);
         end;
         State.Scope_Top := State.Scope_Top - 1;
      end if;
   end Pop_Scope;

   -- Build label table from AST
   procedure Build_Label_Table (State : in out Runtime_State;
                                Prog  : AST_Node_Ptr) is
      Line : AST_Node_Ptr;
      Cmd  : AST_Node_Ptr;
   begin
      if Prog = null or else Prog.Kind /= N_Program then
         return;
      end if;
      Line := Prog.left;
      while Line /= null loop
         if Line.Kind = N_Line and then Line.left /= null then
            -- Check if first command has a tag (label)
            if Line.Value /= Null_Unbounded_String then
               Add_Label (State, To_String (Line.Value), Line);
            end if;
         end if;
         Line := Line.Next;
      end loop;
   end Build_Label_Table;

   -- Evaluate an expression node and return its string value
   function Eval_Expr (State : in out Runtime_State;
                       Node  : AST_Node_Ptr) return String is
      Left_Val  : String (1 .. 10000);
      Left_Len  : Natural := 0;
      Right_Val : String (1 .. 10000);
      Right_Len : Natural := 0;
      Left_Num  : Float;
      Right_Num : Float;
      Result    : Float;
      Bool_Result : Boolean;
   begin
      if Node = null then
         return "";
      end if;

      case Node.Kind is
         -- Literals
         when N_String_Lit =>
            return To_String (Node.Value);
         when N_Number_Lit =>
            return To_String (Node.Value);

         -- Variables
         when N_Variable =>
            declare
               Var_Name : constant String := To_String (Node.Value);
            begin
               if Node.Left /= null then
                  declare
                     Sub : constant String := Eval_Expr (State, Node.Left);
                  begin
                     if Var_Name'Length > 0 and then Var_Name (1) = '^' then
                        return To_String (Database.Get_Global_Subscript
                          (Var_Name (2 .. Var_Name'Last), Sub));
                     else
                        return To_String (Symbol_Table.Get_Subscript
                          (Var_Name, Sub));
                     end if;
                  end;
               end if;
               if Var_Name'Length > 0 and then Var_Name (1) = '^' then
                  return To_String (Database.Get_Global
                    (Var_Name (2 .. Var_Name'Last)));
               else
                  return To_String (Symbol_Table.Get_Var (Var_Name));
               end if;
            end;

         when N_Global =>
            return To_String (Database.Get_Global (To_String (Node.Value)));

         -- Binary arithmetic operators
         when N_Add =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            return From_Float (Left_Num + Right_Num);

         when N_Sub =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            return From_Float (Left_Num - Right_Num);

         when N_Mul =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            return From_Float (Left_Num * Right_Num);

         when N_Div =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            if Right_Num /= 0.0 then
               return From_Float (Left_Num / Right_Num);
            end if;
            return "0";

         when N_IntDiv =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Right_Val (1 .. Right_Len) /= "0" then
               return Integer'Image
                 (Integer (To_Float (Left_Val (1 .. Left_Len))) /
                  Integer (To_Float (Right_Val (1 .. Right_Len))));
            end if;
            return "0";

         when N_Mod =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Right_Val (1 .. Right_Len) /= "0" then
               return Integer'Image
                 (Integer (To_Float (Left_Val (1 .. Left_Len))) mod
                  Integer (To_Float (Right_Val (1 .. Right_Len))));
            end if;
            return "0";

         when N_Pow =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            return From_Float (Left_Num ** Integer (Right_Num));

         -- String operators
         when N_Concat =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            return Left_Val (1 .. Left_Len) & Right_Val (1 .. Right_Len);

         -- Comparison operators
         when N_Eql =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Left_Val (1 .. Left_Len) = Right_Val (1 .. Right_Len) then
               return "1";
            end if;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            if Left_Num = Right_Num then
               return "1";
            end if;
            return "0";

         when N_Neql =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Left_Val (1 .. Left_Len) /= Right_Val (1 .. Right_Len) then
               return "1";
            end if;
            return "0";

         when N_Lt =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            if Left_Num < Right_Num then
               return "1";
            end if;
            return "0";

         when N_Gt =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            if Left_Num > Right_Num then
               return "1";
            end if;
            return "0";

         when N_Lte =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            if Left_Num <= Right_Num then
               return "1";
            end if;
            return "0";

         when N_Gte =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Left_Num := To_Float (Left_Val (1 .. Left_Len));
            Right_Num := To_Float (Right_Val (1 .. Right_Len));
            if Left_Num >= Right_Num then
               return "1";
            end if;
            return "0";

         when N_Follows =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Left_Val (1 .. Left_Len) > Right_Val (1 .. Right_Len) then
               return "1";
            end if;
            return "0";

         when N_SortsAfter =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Left_Val (1 .. Left_Len) > Right_Val (1 .. Right_Len) then
               return "1";
            end if;
            return "0";

         when N_Contains =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            if Index (Left_Val (1 .. Left_Len), Right_Val (1 .. Right_Len)) > 0 then
               return "1";
            end if;
            return "0";

         -- Logical operators
         when N_And =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Bool_Result := (Left_Val (1 .. Left_Len) /= "0" and then
                           Left_Val (1 .. Left_Len) /= "") and then
                          (Right_Val (1 .. Right_Len) /= "0" and then
                           Right_Val (1 .. Right_Len) /= "");
            if Bool_Result then return "1"; end if;
            return "0";

         when N_Or =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            Right_Val (1 .. Eval_Expr (State, Node.right)'Length) :=
              Eval_Expr (State, Node.right);
            Right_Len := Eval_Expr (State, Node.right)'Length;
            Bool_Result := (Left_Val (1 .. Left_Len) /= "0" and then
                           Left_Val (1 .. Left_Len) /= "") or else
                          (Right_Val (1 .. Right_Len) /= "0" and then
                           Right_Val (1 .. Right_Len) /= "");
            if Bool_Result then return "1"; end if;
            return "0";

         -- Unary operators
         when N_UnaryMinus =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            return From_Float (-To_Float (Left_Val (1 .. Left_Len)));

         when N_UnaryPlus =>
            return Eval_Expr (State, Node.left);

         when N_Not =>
            Left_Val (1 .. Eval_Expr (State, Node.left)'Length) :=
              Eval_Expr (State, Node.left);
            Left_Len := Eval_Expr (State, Node.left)'Length;
            if Left_Val (1 .. Left_Len) = "0" or else
              Left_Val (1 .. Left_Len) = "" then
               return "1";
            end if;
            return "0";

         -- Function calls
         when N_Function_Call =>
            declare
               Func_Name : constant String := To_String (Node.Value);
               Args      : array (1 .. 10) of String (1 .. 1000);
               Arg_Lens  : array (1 .. 10) of Natural;
               Arg_Count : Natural := 0;
               Arg_Node  : AST_Node_Ptr;
            begin
               -- Evaluate arguments
               Arg_Node := Node.left;
               while Arg_Node /= null and then Arg_Count < 10 loop
                  Arg_Count := Arg_Count + 1;
                  declare
                     Arg_Val : constant String := Eval_Expr (State, Arg_Node);
                  begin
                     Args (Arg_Count) (1 .. Arg_Val'Length) := Arg_Val;
                     Arg_Lens (Arg_Count) := Arg_Val'Length;
                  end;
                  Arg_Node := Arg_Node.Next;
               end loop;

               -- Dispatch to function
               if Func_Name = "EXTRACT" or else Func_Name = "extract" or else
                 Func_Name = "E" or else Func_Name = "e" then
                  if Arg_Count >= 2 then
                     if Arg_Count >= 3 then
                        return Dollar_EXTRACT
                          (Args (1) (1 .. Arg_Lens (1)),
                           Integer'Value (Args (2) (1 .. Arg_Lens (2))),
                           Integer'Value (Args (3) (1 .. Arg_Lens (3))));
                     else
                        return Dollar_EXTRACT
                          (Args (1) (1 .. Arg_Lens (1)),
                           Integer'Value (Args (2) (1 .. Arg_Lens (2))));
                     end if;
                  end if;
               elsif Func_Name = "LENGTH" or else Func_Name = "length" or else
                 Func_Name = "L" or else Func_Name = "l" then
                  if Arg_Count >= 1 then
                     if Arg_Count >= 2 then
                        return Integer'Image (Dollar_LENGTH
                          (Args (1) (1 .. Arg_Lens (1)),
                           Args (2) (1 .. Arg_Lens (2))));
                     else
                        return Integer'Image (Dollar_LENGTH
                          (Args (1) (1 .. Arg_Lens (1))));
                     end if;
                  end if;
               elsif Func_Name = "PIECE" or else Func_Name = "piece" or else
                 Func_Name = "P" or else Func_Name = "p" then
                  if Arg_Count >= 3 then
                     return Dollar_PIECE
                       (Args (1) (1 .. Arg_Lens (1)),
                        Args (2) (1 .. Arg_Lens (2)),
                        Integer'Value (Args (3) (1 .. Arg_Lens (3))));
                  end if;
               elsif Func_Name = "ASCII" or else Func_Name = "ascii" or else
                 Func_Name = "A" or else Func_Name = "a" then
                  if Arg_Count >= 1 then
                     return Integer'Image (Dollar_ASCII
                       (Args (1) (1 .. Arg_Lens (1))));
                  end if;
               elsif Func_Name = "CHAR" or else Func_Name = "char" or else
                 Func_Name = "C" or else Func_Name = "c" then
                  if Arg_Count >= 1 then
                     return Dollar_CHAR
                       (Integer'Value (Args (1) (1 .. Arg_Lens (1))));
                  end if;
               elsif Func_Name = "DATA" or else Func_Name = "data" or else
                 Func_Name = "D" or else Func_Name = "d" then
                  if Arg_Count >= 1 then
                     declare
                        Arg_Node_Ref : constant AST_Node_Ptr := Node.left;
                        Vname : Unbounded_String;
                     begin
                        if Arg_Node_Ref /= null and then
                          Arg_Node_Ref.Kind = N_Variable then
                           Vname := Arg_Node_Ref.Value;
                        else
                           Vname := To_Unbounded_String (Args (1) (1 .. Arg_Lens (1)));
                        end if;
                        if Length (Vname) > 0 and then
                          Element (Vname, 1) = '^' then
                           return Integer'Image (Database.Global_Data
                             (Slice (Vname, 2, Length (Vname))));
                        else
                           return Integer'Image (Symbol_Table.Var_Data
                             (To_String (Vname)));
                        end if;
                     end;
                  end if;
               elsif Func_Name = "GET" or else Func_Name = "get" or else
                 Func_Name = "G" or else Func_Name = "g" then
                  if Arg_Count >= 1 then
                     declare
                        Arg_Node_Ref : constant AST_Node_Ptr := Node.left;
                        Vname : Unbounded_String;
                        Val   : Unbounded_String;
                     begin
                        if Arg_Node_Ref /= null and then
                          Arg_Node_Ref.Kind = N_Variable then
                           Vname := Arg_Node_Ref.Value;
                        else
                           Vname := To_Unbounded_String (Args (1) (1 .. Arg_Lens (1)));
                        end if;
                        if Length (Vname) > 0 and then
                          Element (Vname, 1) = '^' then
                           Val := Database.Get_Global
                             (Slice (Vname, 2, Length (Vname)));
                        else
                           Val := Symbol_Table.Get_Var (To_String (Vname));
                        end if;
                        if Val = Null_Unbounded_String or else
                          To_String (Val) = "" then
                           if Arg_Count >= 2 then
                              return Args (2) (1 .. Arg_Lens (2));
                           end if;
                           return "";
                        end if;
                        return To_String (Val);
                     end;
                  end if;
               end if;
               return "";
            end;

         when others =>
            return "";
      end case;
   end Eval_Expr;

   -- Execute a SET command
   procedure Exec_Set (State : in out Runtime_State;
                       Node  : AST_Node_Ptr) is
      Var_Name : Unbounded_String;
      Value    : String (1 .. 10000);
      Val_Len  : Natural := 0;
   begin
      if Node.left /= null and then Node.left.Kind = N_Variable then
         Var_Name := Node.left.Value;
         if Node.right /= null then
            declare
               Val : constant String := Eval_Expr (State, Node.right);
            begin
               Value (1 .. Val'Length) := Val;
               Val_Len := Val'Length;
            end;
            if Node.left.left /= null then
               declare
                  Sub : constant String := Eval_Expr (State, Node.left.left);
               begin
                  if To_String (Var_Name)'Length > 0 and then
                    To_String (Var_Name) (1) = '^' then
                     Database.Set_Global_Subscript
                       (To_String (Var_Name) (2 .. To_String (Var_Name)'Length),
                        Sub, Value (1 .. Val_Len));
                  else
                     Symbol_Table.Set_Subscript
                       (To_String (Var_Name), Sub, Value (1 .. Val_Len));
                  end if;
               end;
            else
               if To_String (Var_Name)'Length > 0 and then
                 To_String (Var_Name) (1) = '^' then
                  Database.Set_Global
                    (To_String (Var_Name) (2 .. To_String (Var_Name)'Length),
                     Value (1 .. Val_Len));
               else
                  Symbol_Table.Set_Var
                    (To_String (Var_Name), Value (1 .. Val_Len));
               end if;
            end if;
         end if;
      end if;
   end Exec_Set;

   -- Execute a WRITE command
   procedure Exec_Write (State : in out Runtime_State;
                         Node  : AST_Node_Ptr) is
      Value : String (1 .. 10000);
      VLen  : Natural := 0;
   begin
      if Node.left /= null then
         declare
            Val : constant String := Eval_Expr (State, Node.left);
         begin
            Value (1 .. Val'Length) := Val;
            VLen := Val'Length;
         end;
         IO.Write (Value (1 .. VLen));
      end if;
   end Exec_Write;

   -- Execute a single command node
   procedure Execute_Command (State : in out Runtime_State;
                              Node  : AST_Node_Ptr) is
   begin
      if Node = null or else State.Halted or else State.Skip_Remainder then
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
            -- QUIT with optional return value
            if Node.left /= null then
               State.Quit_Value := To_Unbounded_String
                 (Eval_Expr (State, Node.left));
            end if;
            -- Pop scope if in DO context
            Pop_Scope (State);
            State.Halted := True;
         when N_If =>
            if Node.left /= null then
               declare
                  Cond : constant String := Eval_Expr (State, Node.left);
               begin
                  State.Test_Result := Cond /= "" and then Cond /= "0";
               end;
            end if;
         when N_Else =>
            -- ELSE: skip rest of line if $TEST is true
            if State.Test_Result then
               State.Skip_Remainder := True;
            end if;
         when N_For =>
            -- FOR var=start:increment:end
            -- Structure: Node.Value = var name
            --            Node.left = start expression
            --            Node.right = increment expression
            --            Node.Next.left = end expression
            --            Node.Next.right = body command
            if Node.Value /= Null_Unbounded_String and then
              Node.left /= null then
               declare
                  Var_Name : constant String := To_String (Node.Value);
                  Start_Val : Float;
                  Incr_Val  : Float;
                  End_Val   : Float;
                  Cur_Val   : Float;
                  Body_Cmd  : AST_Node_Ptr;
               begin
                  -- Get start value
                  Start_Val := To_Float (Eval_Expr (State, Node.left));
                  -- Get increment value
                  if Node.right /= null then
                     Incr_Val := To_Float (Eval_Expr (State, Node.right));
                  else
                     Incr_Val := 1.0;
                  end if;
                  -- Get end value
                  if Node.Next /= null and then Node.Next.left /= null then
                     End_Val := To_Float (Eval_Expr (State, Node.Next.left));
                  else
                     End_Val := Start_Val;
                  end if;
                  -- Get body command
                  if Node.Next /= null then
                     Body_Cmd := Node.Next.right;
                  else
                     Body_Cmd := null;
                  end if;
                  -- Execute FOR loop
                  Cur_Val := Start_Val;
                  if Incr_Val > 0.0 then
                     while Cur_Val <= End_Val and then not State.Halted loop
                        Symbol_Table.Set_Var (Var_Name, From_Float (Cur_Val));
                        -- Execute body commands
                        if Body_Cmd /= null then
                           Execute_Command (State, Body_Cmd);
                        end if;
                        Cur_Val := Cur_Val + Incr_Val;
                     end loop;
                  elsif Incr_Val < 0.0 then
                     while Cur_Val >= End_Val and then not State.Halted loop
                        Symbol_Table.Set_Var (Var_Name, From_Float (Cur_Val));
                        if Body_Cmd /= null then
                           Execute_Command (State, Body_Cmd);
                        end if;
                        Cur_Val := Cur_Val + Incr_Val;
                     end loop;
                  end if;
               end;
            end if;
         when N_Do =>
            -- DO label: call subroutine
            if Node.Value /= Null_Unbounded_String then
               declare
                  Label : constant String := To_String (Node.Value);
                  Target : AST_Node_Ptr;
               begin
                  Target := Find_Label (State, Label);
                  if Target /= null then
                     -- Save current state and jump
                     Execute_Line (State, Target);
                  end if;
               end;
            end if;
         when N_New =>
            -- NEW var1,var2,... : save and clear variables
            if Node.Value /= Null_Unbounded_String then
               declare
                  Var_List : constant String := To_String (Node.Value);
                  Start    : Natural := 1;
                  I        : Natural;
               begin
                  -- Parse comma-separated variable names
                  loop
                     I := Start;
                     while I <= Var_List'Length and then
                       Var_List (I) /= ',' loop
                        I := I + 1;
                     end loop;
                     Push_Scope (State, Var_List (Start .. I - 1));
                     exit when I > Var_List'Length;
                     Start := I + 1;
                  end loop;
               end;
            end if;
         when N_Goto =>
            -- GOTO label: jump to label
            if Node.Value /= Null_Unbounded_String then
               declare
                  Label : constant String := To_String (Node.Value);
                  Target : AST_Node_Ptr;
               begin
                  Target := Find_Label (State, Label);
                  if Target /= null then
                     -- Jump to target (simplified: just set halted)
                     -- In a full implementation, this would change the PC
                     State.Halted := True;
                  end if;
               end;
            end if;
         when N_Hang =>
            -- HANG: delay (simplified)
            null;
         when N_Kill =>
            if Node.left /= null and then Node.left.Kind = N_Variable then
               declare
                  Vname : constant String := To_String (Node.left.Value);
               begin
                  if Vname'Length > 0 and then Vname (1) = '^' then
                     Database.Kill_Global (Vname (2 .. Vname'Last));
                  else
                     Symbol_Table.Kill_Var (Vname);
                  end if;
               end;
            end if;
         when N_Read =>
            if Node.left /= null and then Node.left.Kind = N_Variable then
               declare
                  Input : constant String := IO.Read;
               begin
                  Symbol_Table.Set_Var (To_String (Node.left.Value), Input);
               end;
            end if;
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
      -- Reset skip flag for new line
      State.Skip_Remainder := False;
      Cmd := Line.left;
      while Cmd /= null and then not State.Halted loop
         -- If this is a FOR command, execute it with the rest of the line as body
         if Cmd.Kind = N_For then
            Execute_Command (State, Cmd);
            -- Skip the body commands since FOR already executed them
            exit;
         else
            Execute_Command (State, Cmd);
         end if;
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
      -- Build label table
      Build_Label_Table (State, Prog);
      -- Execute
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

   function Get_Quit_Value (State : Runtime_State) return String is
   begin
      return To_String (State.Quit_Value);
   end Get_Quit_Value;

end Runtime;
