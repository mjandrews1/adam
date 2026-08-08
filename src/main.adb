-- Package: adam
-- File:    src/main.adb
-- Summary: M/MUMPS in Ada - A port of RFC to Ada language
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Symbol_Table;
with Database;
with Pattern;
with IO;
with String_Funcs;          use String_Funcs;
with Mumps_Types;           use Mumps_Types;
with Lexer;                 use Lexer;
with Parser;                use Parser;
with Runtime;               use Runtime;
with Conformance;

procedure Main is
begin
   Put_Line ("adam - M/MUMPS in Ada");
   Put_Line ("A port of RFC to Ada language");
   New_Line;

   -- Run conformance tests
   Conformance;
   New_Line;

   -- Demo operations
   Put_Line ("Demo Operations:");
   Put_Line ("================");

   -- Test Symbol Table
   Put_Line ("Symbol Table:");
   Symbol_Table.Set_Var ("X", "42");
   Symbol_Table.Set_Var ("NAME", "John Doe");
   Put_Line ("  X = " & To_String (Symbol_Table.Get_Var ("X")));
   Put_Line ("  NAME = " & To_String (Symbol_Table.Get_Var ("NAME")));
   Put_Line ("  X exists: " & Boolean'Image (Symbol_Table.Var_Exists ("X")));
   Put_Line ("  Y exists: " & Boolean'Image (Symbol_Table.Var_Exists ("Y")));
   New_Line;

   -- Test subscripts
   Put_Line ("Subscripted Variables:");
   Symbol_Table.Set_Subscript ("ARR", "1", "first");
   Symbol_Table.Set_Subscript ("ARR", "2", "second");
   Symbol_Table.Set_Subscript ("ARR", "3", "third");
   Put_Line ("  ARR(1) = " & To_String (Symbol_Table.Get_Subscript ("ARR", "1")));
   Put_Line ("  ARR(2) = " & To_String (Symbol_Table.Get_Subscript ("ARR", "2")));
   Put_Line ("  ARR(3) = " & To_String (Symbol_Table.Get_Subscript ("ARR", "3")));
   Put_Line ("  $DATA(ARR) = " & Natural'Image (Symbol_Table.Var_Data ("ARR")));
   Put_Line ("  $ORDER(ARR, ) = " &
             To_String (Symbol_Table.Var_Order ("ARR")));
   Put_Line ("  $ORDER(ARR, 1) = " &
             To_String (Symbol_Table.Var_Order ("ARR", "1")));
   New_Line;

   -- List all variables
   Put_Line ("All Variables:");
   Symbol_Table.List_All;
   New_Line;

   -- Test Database
   Put_Line ("Database Operations:");
   Put_Line ("--------------------");
   Database.Set_Global ("TEST", "value1");
   Database.Set_Global ("DATA", "value2");
   Put_Line ("  ^TEST = " & To_String (Database.Get_Global ("TEST")));
   Put_Line ("  ^DATA = " & To_String (Database.Get_Global ("DATA")));
   New_Line;

   -- Test subscripted globals
   Put_Line ("Subscripted Globals:");
   Database.Set_Global_Subscript ("GARR", "1", "gfirst");
   Database.Set_Global_Subscript ("GARR", "2", "gsecond");
   Database.Set_Global ("GARR", "groot");
   Put_Line ("  ^GARR = " & To_String (Database.Get_Global ("GARR")));
   Put_Line ("  ^GARR(1) = " & To_String (Database.Get_Global_Subscript ("GARR", "1")));
   Put_Line ("  ^GARR(2) = " & To_String (Database.Get_Global_Subscript ("GARR", "2")));
   Put_Line ("  $DATA(^GARR) = " & Natural'Image (Database.Global_Data ("GARR")));
   Put_Line ("  $ORDER(^GARR, ) = " &
             To_String (Database.Global_Order ("GARR")));
   New_Line;

   -- List all globals
   Put_Line ("All Globals:");
   Database.List_All_Globals;
   New_Line;

   -- Test Pattern Matching
   Put_Line ("Pattern Matching:");
   Put_Line ("-----------------");
   Put_Line ("  Match 'ABC' against '3A': " &
     Boolean'Image (Pattern.Match ("ABC", "3A")));
   Put_Line ("  Match '123' against '3N': " &
     Boolean'Image (Pattern.Match ("123", "3N")));
   Put_Line ("  Match 'A1B' against '1A1N1A': " &
     Boolean'Image (Pattern.Match ("A1B", "1A1N1A")));
   Put_Line ("  Match 'AB' against '3A': " &
     Boolean'Image (Pattern.Match ("AB", "3A")));
   New_Line;

   -- Test I/O
   Put_Line ("I/O Operations:");
   Put_Line ("---------------");
   Put_Line ("  Current device: " & Natural'Image (IO.Current_Device));
   IO.Open_Device (1, "test_device", IO.File);
   Put_Line ("  Opened device 1: " & Boolean'Image (IO.Is_Open (1)));
   IO.Use_Device (1);
   IO.Write ("Test output");
   Put_Line ("  Cursor X after write: " & Natural'Image (IO.Get_X (1)));
   IO.Write_Newline;
   Put_Line ("  Cursor X after newline: " & Natural'Image (IO.Get_X (1)));
   IO.Close_Device (1);
   IO.Use_Device (0);
   New_Line;

   -- Test String Functions
   Put_Line ("String Functions:");
   Put_Line ("-----------------");
   Put_Line ("  $ASCII('A') = " & Integer'Image (Dollar_ASCII ("A")));
   Put_Line ("  $CHAR(65) = " & Dollar_CHAR (65));
   Put_Line ("  $LENGTH('Hello') = " & Natural'Image (Dollar_LENGTH ("Hello")));
   Put_Line ("  $EXTRACT('ABCDEF', 2, 4) = " & Dollar_EXTRACT ("ABCDEF", 2, 4));
   Put_Line ("  $FIND('ABCDEF', 'CD') = " & Natural'Image (Dollar_FIND ("ABCDEF", "CD")));
   Put_Line ("  $PIECE('A^B^C', '^', 2) = " & Dollar_PIECE ("A^B^C", "^", 2));
   Put_Line ("  $TRANSLATE('ABC', 'AC', 'XY') = " & Dollar_TRANSLATE ("ABC", "AC", "XY"));
   Put_Line ("  $REVERSE('ABC') = " & Dollar_REVERSE ("ABC"));
   Put_Line ("  $JUSTIFY('ABC', 6) = " & Dollar_JUSTIFY ("ABC", 6));
   New_Line;

   -- Test Lexer
   Put_Line ("Lexer:");
   Put_Line ("------");
   declare
      Lex : Lexer_State;
      Tok : Token;
   begin
      Lex := Create_Lexer ("SET X = 42");
      loop
         Tok := Next_Token (Lex);
         exit when Tok.Kind = Tok_EOF;
         Put_Line ("  Token: " & Token_Type'Image (Tok.Kind) &
                   " = " & Tok.Value (1 .. Tok.Val_Len));
      end loop;
   end;
   New_Line;

   -- Test Parser and Runtime
   Put_Line ("Parser & Runtime:");
   Put_Line ("-----------------");
   declare
      P    : Parser_State;
      R    : Runtime_State;
      Prog : AST_Node_Ptr;
   begin
      P := Create_Parser ("SET DEMO = Hello");
      Prog := Parse_Program (P);
      R := Create_Runtime;
      Execute (R, Prog);
      Put_Line ("  Executed: SET DEMO = Hello");
      Put_Line ("  DEMO = " & To_String (Symbol_Table.Get_Var ("DEMO")));
      Destroy_AST (Prog);
   end;
   New_Line;

   Put_Line ("adam is ready for MUMPS development!");
end Main;
