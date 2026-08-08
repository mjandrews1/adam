-- Package: adam
-- File:    src/main.adb
-- Summary: M/MUMPS in Ada - A port of RFC to Ada language
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Symbol_Table;

procedure Main is
begin
   Put_Line ("adam - M/MUMPS in Ada");
   Put_Line ("A port of RFC to Ada language");
   New_Line;

   -- Test Symbol Table
   Put_Line ("Symbol Table Operations:");
   Put_Line ("------------------------");
   Symbol_Table.Set_Var ("X", "42");
   Symbol_Table.Set_Var ("NAME", "John Doe");
   Put_Line ("X = " & To_String (Symbol_Table.Get_Var ("X")));
   Put_Line ("NAME = " & To_String (Symbol_Table.Get_Var ("NAME")));
   Put_Line ("X exists: " & Boolean'Image (Symbol_Table.Var_Exists ("X")));
   Put_Line ("Y exists: " & Boolean'Image (Symbol_Table.Var_Exists ("Y")));
   New_Line;

   -- List all variables
   Put_Line ("All Variables:");
   Put_Line ("--------------");
   Symbol_Table.List_All;
   New_Line;

   Put_Line ("adam is ready for MUMPS development!");
end Main;
