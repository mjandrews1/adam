-- Package: adam
-- File:    src/main.adb
-- Summary: M/MUMPS in Ada - A port of RFC to Ada language
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Symbol_Table;
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

   Put_Line ("adam is ready for MUMPS development!");
end Main;
