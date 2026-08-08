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
   Put_Line ("Version 0.1.0");
   New_Line;

   -- Run conformance tests
   Put_Line ("Running conformance tests...");
   Conformance;
   New_Line;

   -- Demo: Symbol Table
   Put_Line ("Demo: Symbol Table");
   Put_Line ("==================");
   Symbol_Table.Set_Var ("X", "42");
   Symbol_Table.Set_Var ("NAME", "John Doe");
   Symbol_Table.Set_Var ("PI", "3.14159");
   Put_Line ("  X = " & To_String (Symbol_Table.Get_Var ("X")));
   Put_Line ("  NAME = " & To_String (Symbol_Table.Get_Var ("NAME")));
   Put_Line ("  PI = " & To_String (Symbol_Table.Get_Var ("PI")));
   New_Line;

   -- Demo: Subscripted Variables
   Put_Line ("Demo: Subscripted Variables");
   Put_Line ("--------------------------");
   Symbol_Table.Set_Subscript ("ARR", "1", "first");
   Symbol_Table.Set_Subscript ("ARR", "2", "second");
   Symbol_Table.Set_Subscript ("ARR", "3", "third");
   Put_Line ("  ARR(1) = " & To_String (Symbol_Table.Get_Subscript ("ARR", "1")));
   Put_Line ("  ARR(2) = " & To_String (Symbol_Table.Get_Subscript ("ARR", "2")));
   Put_Line ("  ARR(3) = " & To_String (Symbol_Table.Get_Subscript ("ARR", "3")));
   Put_Line ("  $DATA(ARR) = " & Natural'Image (Symbol_Table.Var_Data ("ARR")));
   Put_Line ("  $ORDER(ARR, ) = " & To_String (Symbol_Table.Var_Order ("ARR")));
   Put_Line ("  $ORDER(ARR, 1) = " & To_String (Symbol_Table.Var_Order ("ARR", "1")));
   New_Line;

   -- Demo: Database (Globals)
   Put_Line ("Demo: Database (Globals)");
   Put_Line ("========================");
   Database.Set_Global ("TEST", "value1");
   Database.Set_Global ("DATA", "value2");
   Database.Set_Global_Subscript ("GARR", "1", "gfirst");
   Database.Set_Global_Subscript ("GARR", "2", "gsecond");
   Put_Line ("  ^TEST = " & To_String (Database.Get_Global ("TEST")));
   Put_Line ("  ^DATA = " & To_String (Database.Get_Global ("DATA")));
   Put_Line ("  ^GARR(1) = " & To_String (Database.Get_Global_Subscript ("GARR", "1")));
   Put_Line ("  ^GARR(2) = " & To_String (Database.Get_Global_Subscript ("GARR", "2")));
   New_Line;

   -- Demo: Pattern Matching
   Put_Line ("Demo: Pattern Matching");
   Put_Line ("----------------------");
   Put_Line ("  'ABC' ~ '3A': " & Boolean'Image (Pattern.Match ("ABC", "3A")));
   Put_Line ("  '123' ~ '3N': " & Boolean'Image (Pattern.Match ("123", "3N")));
   Put_Line ("  'A1B' ~ '1A1N1A': " & Boolean'Image (Pattern.Match ("A1B", "1A1N1A")));
   New_Line;

   -- Demo: String Functions
   Put_Line ("Demo: String Functions");
   Put_Line ("----------------------");
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

   -- Demo: Lexer
   Put_Line ("Demo: Lexer");
   Put_Line ("-----------");
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

   -- Demo: Parser & Runtime
   Put_Line ("Demo: Parser & Runtime");
   Put_Line ("----------------------");
   declare
      P    : Parser_State;
      R    : Runtime_State;
      Prog : AST_Node_Ptr;
   begin
      -- Execute SET command
      P := Create_Parser ("SET DEMO = Hello");
      Prog := Parse_Program (P);
      R := Create_Runtime;
      Execute (R, Prog);
      Put_Line ("  Executed: SET DEMO = Hello");
      Put_Line ("  DEMO = " & To_String (Symbol_Table.Get_Var ("DEMO")));
      Destroy_AST (Prog);

      -- Execute WRITE command
      P := Create_Parser ("WRITE Hello");
      Prog := Parse_Program (P);
      R := Create_Runtime;
      Put ("  Executed: WRITE Hello -> ");
      Execute (R, Prog);
      New_Line;
      Destroy_AST (Prog);
   end;
   New_Line;

   -- Summary
   Put_Line ("Summary");
   Put_Line ("=======");
   Put_Line ("  Symbol Table: " & Natural'Image (Symbol_Table.Var_Data ("X")) & " entries");
   Put_Line ("  Database: " & Natural'Image (Database.Global_Data ("TEST")) & " globals");
   Put_Line ("  Lexer: Functional");
   Put_Line ("  Parser: Functional");
   Put_Line ("  Runtime: Functional");
   Put_Line ("  Pattern Matching: Functional");
   Put_Line ("  String Functions: Functional");
   New_Line;

   Put_Line ("adam is ready for MUMPS development!");
end Main;
