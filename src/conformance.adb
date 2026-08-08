-- Package: adam
-- File:    src/conformance.adb
-- Summary: MUMPS Conformance Tests
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Symbol_Table;

procedure Conformance is
   Total  : Natural := 0;
   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Assert (Condition : Boolean; Test_Name : String) is
   begin
      Total := Total + 1;
      if Condition then
         Passed := Passed + 1;
         Put_Line ("PASS: " & Test_Name);
      else
         Failed := Failed + 1;
         Put_Line ("FAIL: " & Test_Name);
      end if;
   end Assert;

begin
   Put_Line ("adam Conformance Test Suite");
   Put_Line ("===========================");
   New_Line;

   -- Symbol Table Tests
   Put_Line ("Symbol Table Tests:");
   Put_Line ("===================");

   -- SET and GET
   Symbol_Table.Set_Var ("X", "42");
   Assert (To_String (Symbol_Table.Get_Var ("X")) = "42",
           "SET and GET basic variable");

   -- Variable exists
   Assert (Symbol_Table.Var_Exists ("X"),
           "Variable exists check");
   Assert (not Symbol_Table.Var_Exists ("Y"),
           "Variable does not exist check");

   -- KILL
   Symbol_Table.Kill_Var ("X");
   Assert (not Symbol_Table.Var_Exists ("X"),
           "KILL variable");

   -- $DATA
   Symbol_Table.Set_Var ("DATA_TEST", "value");
   Assert (Symbol_Table.Var_Data ("DATA_TEST") = 1,
           "$DATA with value");
   Assert (Symbol_Table.Var_Data ("NONEXIST") = 0,
           "$DATA without value");

   -- Subscripted variables
   Symbol_Table.Set_Subscript ("ARR", "1", "first");
   Symbol_Table.Set_Subscript ("ARR", "2", "second");
   Symbol_Table.Set_Subscript ("ARR", "3", "third");
   Assert (To_String (Symbol_Table.Get_Subscript ("ARR", "1")) = "first",
           "SET and GET subscripted variable");
   Assert (To_String (Symbol_Table.Get_Subscript ("ARR", "2")) = "second",
           "GET second subscript");
   Assert (To_String (Symbol_Table.Get_Subscript ("ARR", "3")) = "third",
           "GET third subscript");

   -- $DATA with subscripts only (code 10)
   Assert (Symbol_Table.Var_Data ("ARR") = 10,
           "$DATA with subscripts only");

   -- $DATA with data and subscripts (code 11)
   Symbol_Table.Set_Var ("ARR", "root_value");
   Assert (Symbol_Table.Var_Data ("ARR") = 11,
           "$DATA with data and subscripts");

   -- $DATA on subscripted node
   Assert (Symbol_Table.Subscript_Data ("ARR", "1") = 1,
           "$DATA on subscripted node with value");
   Assert (Symbol_Table.Subscript_Data ("ARR", "99") = 0,
           "$DATA on non-existent subscript");

   -- $ORDER - get first subscript
   Assert (To_String (Symbol_Table.Var_Order ("ARR")) = "1",
           "$ORDER returns first subscript");

   -- $ORDER - get next subscript
   Assert (To_String (Symbol_Table.Var_Order ("ARR", "1")) = "2",
           "$ORDER returns next subscript");

   -- $ORDER - get next subscript again
   Assert (To_String (Symbol_Table.Var_Order ("ARR", "2")) = "3",
           "$ORDER returns third subscript");

   -- $ORDER - no more subscripts
   Assert (To_String (Symbol_Table.Var_Order ("ARR", "3")) = "",
           "$ORDER returns empty at end");

   -- KILL with subscripts
   Symbol_Table.Kill_Subscript ("ARR", "2");
   Assert (not Symbol_Table.Subscript_Exists ("ARR", "2"),
           "KILL subscripted variable");
   Assert (Symbol_Table.Subscript_Exists ("ARR", "1"),
           "Other subscripts still exist");

   -- KILL all subscripts
   Symbol_Table.Kill_Var ("ARR");
   Assert (Symbol_Table.Var_Data ("ARR") = 0,
           "KILL removes all subscripts");

   -- MERGE
   Symbol_Table.Set_Var ("SRC", "src_value");
   Symbol_Table.Set_Subscript ("SRC", "1", "src_sub1");
   Symbol_Table.Set_Subscript ("SRC", "2", "src_sub2");
   Symbol_Table.Merge_Var ("DST", "SRC");
   Assert (To_String (Symbol_Table.Get_Var ("DST")) = "src_value",
           "MERGE copies root value");
   Assert (To_String (Symbol_Table.Get_Subscript ("DST", "1")) = "src_sub1",
           "MERGE copies subscript 1");
   Assert (To_String (Symbol_Table.Get_Subscript ("DST", "2")) = "src_sub2",
           "MERGE copies subscript 2");

   New_Line;

   -- Summary
   Put_Line ("Test Results:");
   Put_Line ("=============");
   Put_Line ("Total tests: " & Natural'Image (Total));
   Put_Line ("Passed: " & Natural'Image (Passed));
   Put_Line ("Failed: " & Natural'Image (Failed));
   if Failed = 0 then
      Put_Line ("All tests passed!");
   else
      Put_Line ("Some tests failed.");
   end if;
end Conformance;
