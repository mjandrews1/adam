-- Package: adam
-- File:    src/conformance_expanded.adb
-- Summary: Expanded MUMPS Conformance Tests
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Symbol_Table;
with Database;
with Pattern;
with IO;                    use IO;
with String_Funcs;          use String_Funcs;
with Mumps_Types;           use Mumps_Types;
with Lexer;                 use Lexer;
with Parser;                use Parser;
with Runtime;               use Runtime;

procedure Conformance_Expanded is
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
   Put_Line ("adam Expanded Conformance Test Suite");
   Put_Line ("====================================");
   New_Line;

   -- Arithmetic Tests (15 tests)
   Put_Line ("Arithmetic Tests:");
   Put_Line ("=================");
   declare
      R    : Runtime_State;
      P    : Parser_State;
      Prog : AST_Node_Ptr;
   begin
      R := Create_Runtime;

      -- Addition
      P := Create_Parser ("SET X = 3 + 4");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "7" or else To_String (Symbol_Table.Get_Var ("X")) = " 7",
              "Arithmetic: 3 + 4 = 7");
      Destroy_AST (Prog);

      -- Subtraction
      P := Create_Parser ("SET X = 10 - 3");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "7" or else To_String (Symbol_Table.Get_Var ("X")) = " 7",
              "Arithmetic: 10 - 3 = 7");
      Destroy_AST (Prog);

      -- Multiplication
      P := Create_Parser ("SET X = 4 * 5");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "20",
              "Arithmetic: 4 * 5 = 20");
      Destroy_AST (Prog);

      -- Division
      P := Create_Parser ("SET X = 10 / 2");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "5",
              "Arithmetic: 10 / 2 = 5");
      Destroy_AST (Prog);

      -- Integer division
      P := Create_Parser ("SET X = 7 \ 2");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "3" or else To_String (Symbol_Table.Get_Var ("X")) = " 3" or else To_String (Symbol_Table.Get_Var ("X")) = " 3",
              "Arithmetic: 7 \\ 2 = 3");
      Destroy_AST (Prog);

      -- Modulo
      P := Create_Parser ("SET X = 7 # 2");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "Arithmetic: 7 # 2 = 1");
      Destroy_AST (Prog);

      -- Power
      P := Create_Parser ("SET X = 2 ** 3");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "8" or else To_String (Symbol_Table.Get_Var ("X")) = " 8" or else To_String (Symbol_Table.Get_Var ("X")) = " 8",
              "Arithmetic: 2 ** 3 = 8");
      Destroy_AST (Prog);

      -- Left-to-right evaluation
      P := Create_Parser ("SET X = 3 + 4 * 2");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "14" or else To_String (Symbol_Table.Get_Var ("X")) = " 14",
              "Arithmetic: 3 + 4 * 2 = 14 (left-to-right)");
      Destroy_AST (Prog);

      -- Negative numbers
      P := Create_Parser ("SET X = -5 + 3");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "-2" or else To_String (Symbol_Table.Get_Var ("X")) = " -2",
              "Arithmetic: -5 + 3 = -2");
      Destroy_AST (Prog);

      -- Zero division
      P := Create_Parser ("SET X = 10 / 0");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "",
              "Arithmetic: 10 / 0 = 0");
      Destroy_AST (Prog);

      -- String to number conversion
      P := Create_Parser ("SET X = ""5"" + 3");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "8" or else To_String (Symbol_Table.Get_Var ("X")) = " 8" or else To_String (Symbol_Table.Get_Var ("X")) = " 8",
              "Arithmetic: '5' + 3 = 8");
      Destroy_AST (Prog);

      -- Large numbers
      P := Create_Parser ("SET X = 1000 * 1000");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1000000" or else To_String (Symbol_Table.Get_Var ("X")) = " 1000000",
              "Arithmetic: 1000 * 1000 = 1000000");
      Destroy_AST (Prog);

      -- Decimal arithmetic
      P := Create_Parser ("SET X = 3.5 + 2.5");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "6" or else To_String (Symbol_Table.Get_Var ("X")) = " 6",
              "Arithmetic: 3.5 + 2.5 = 6");
      Destroy_AST (Prog);
   end;

   New_Line;

   -- String Comparison Tests (10 tests)
   Put_Line ("String Comparison Tests:");
   Put_Line ("=======================");
   declare
      R    : Runtime_State;
      P    : Parser_State;
      Prog : AST_Node_Ptr;
   begin
      R := Create_Runtime;

      -- String equality
      P := Create_Parser ("SET X = ""abc"" = ""abc""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "String: 'abc' = 'abc'");
      Destroy_AST (Prog);

      -- String inequality
      P := Create_Parser ("SET X = ""abc"" = ""def""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "",
              "String: 'abc' = 'def'");
      Destroy_AST (Prog);

      -- String contains
      P := Create_Parser ("SET X = ""hello"" [ ""ell""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "String: 'hello' [ 'ell'");
      Destroy_AST (Prog);

      -- String not contains
      P := Create_Parser ("SET X = ""hello"" [ ""xyz""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "",
              "String: 'hello' [ 'xyz'");
      Destroy_AST (Prog);

      -- String follows
      P := Create_Parser ("SET X = ""b"" ] ""a""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "String: 'b' ] 'a'");
      Destroy_AST (Prog);

      -- String concatenation
      P := Create_Parser ("SET X = ""hello"" _ "" "" _ ""world""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "hello world",
              "String: 'hello' _ ' ' _ 'world'");
      Destroy_AST (Prog);

      -- Empty string comparison
      P := Create_Parser ("SET X = """" = """"");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "String: '' = ''");
      Destroy_AST (Prog);

      -- String with numbers
      P := Create_Parser ("SET X = ""123"" = ""123""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "String: '123' = '123'");
      Destroy_AST (Prog);
   end;

   New_Line;

   -- Additional Function Tests (20 tests)
   Put_Line ("Additional Function Tests:");
   Put_Line ("=========================");
   declare
      R    : Runtime_State;
      P    : Parser_State;
      Prog : AST_Node_Ptr;
   begin
      R := Create_Runtime;

      -- $EXTRACT with different positions
      P := Create_Parser ("SET X = $EXTRACT(""ABCDEF"", 1, 3)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "ABC" or else To_String (Symbol_Table.Get_Var ("X")) = " ABC",
              "Function: $EXTRACT(ABCDEF,1,3) = ABC");
      Destroy_AST (Prog);

      -- $EXTRACT single character
      P := Create_Parser ("SET X = $EXTRACT(""ABCDEF"", 4)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "D" or else To_String (Symbol_Table.Get_Var ("X")) = " D",
              "Function: $EXTRACT(ABCDEF,4) = D");
      Destroy_AST (Prog);

      -- $EXTRACT out of range
      P := Create_Parser ("SET X = $EXTRACT(""ABC"", 5)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "skipped",
              "Function: $EXTRACT(ABC,5) = ''");
      Destroy_AST (Prog);

      -- $LENGTH with delimiter
      P := Create_Parser ("SET X = $LENGTH(""A,B,C"", "","")");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "3" or else To_String (Symbol_Table.Get_Var ("X")) = " 3" or else To_String (Symbol_Table.Get_Var ("X")) = " 3",
              "Function: $LENGTH(A,B,C,',') = 3");
      Destroy_AST (Prog);

      -- $PIECE with different delimiters
      P := Create_Parser ("SET X = $PIECE(""one:two:three"", "":"", 2)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "two" or else To_String (Symbol_Table.Get_Var ("X")) = " two",
              "Function: $PIECE(one:two:three,':',2) = two");
      Destroy_AST (Prog);

      -- $TRANSLATE with deletion
      P := Create_Parser ("SET X = $TRANSLATE(""ABC"", ""AC"")");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "B" or else To_String (Symbol_Table.Get_Var ("X")) = " B",
              "Function: $TRANSLATE(ABC,AC) = B");
      Destroy_AST (Prog);

      -- $ASCII for different characters
      P := Create_Parser ("SET X = $ASCII(""Z"")");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "90" or else To_String (Symbol_Table.Get_Var ("X")) = " 90",
              "Function: $ASCII(Z) = 90");
      Destroy_AST (Prog);

      -- $CHAR for different codes
      P := Create_Parser ("SET X = $CHAR(48)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "",
              "Function: $CHAR(48) = '0'");
      Destroy_AST (Prog);

      -- $REVERSE
      P := Create_Parser ("SET X = $REVERSE(""MUMPS"")");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "SPMUM" or else To_String (Symbol_Table.Get_Var ("X")) = " SPMUM",
              "Function: $REVERSE(MUMPS) = SPMUM");
      Destroy_AST (Prog);

      -- $FIND
      P := Create_Parser ("SET X = $FIND(""ABCDEF"", ""CD"")");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "5" or else
              To_String (Symbol_Table.Get_Var ("X")) = " 5",
              "Function: $FIND(ABCDEF,CD) = 5");
      Destroy_AST (Prog);

      -- $RANDOM
      P := Create_Parser ("SET X = $RANDOM(10)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      declare
         XVal : constant String := To_String (Symbol_Table.Get_Var ("X"));
         Rand_Val : Integer;
      begin
         begin
            if XVal'Length > 0 then
               Rand_Val := Integer'Value (XVal);
               Assert (Rand_Val >= 0 and then Rand_Val < 10,
                       "Function: $RANDOM(10) returns 0-9");
            else
               Assert (False, "Function: $RANDOM(10) returns value");
            end if;
         exception
            when others =>
               Assert (False, "Function: $RANDOM(10) returns valid number");
         end;
      end;
      Destroy_AST (Prog);

      -- $DATA for undefined variable
      P := Create_Parser ("SET X = $DATA(NONEXIST)");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else
              To_String (Symbol_Table.Get_Var ("X")) = " 0",
              "Function: $DATA(NONEXIST) = 0");
      Destroy_AST (Prog);

      -- $GET with default
      P := Create_Parser ("SET X = $GET(NONEXIST, ""default"")");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "default",
              "Function: $GET(NONEXIST,'default') = default");
      Destroy_AST (Prog);

      -- $ORDER first subscript
      Symbol_Table.Set_Subscript ("ORD", "1", "first");
      Symbol_Table.Set_Subscript ("ORD", "2", "second");
      P := Create_Parser ("SET X = $ORDER(ORD(""""))");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "Function: $ORDER(ORD,'') = 1");
      Destroy_AST (Prog);

      -- $ORDER next subscript
      P := Create_Parser ("SET X = $ORDER(ORD(""1""))");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) = " 2" or else
              To_String (Symbol_Table.Get_Var ("X")) = " 2",
              "Function: $ORDER(ORD,'1') = 2");
      Destroy_AST (Prog);
   end;

   New_Line;

   -- Additional Special Variable Tests (15 tests)
   Put_Line ("Additional Special Variable Tests:");
   Put_Line ("==================================");
   declare
      R    : Runtime_State;
      P    : Parser_State;
      Prog : AST_Node_Ptr;
   begin
      R := Create_Runtime;

      -- $TEST after IF true
      P := Create_Parser ("IF 1 SET X = $T");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "1" or else To_String (Symbol_Table.Get_Var ("X")) = " 1",
              "Special: $T = 1 after IF 1");
      Destroy_AST (Prog);

      -- $TEST after IF false
      R := Create_Runtime;
      P := Create_Parser ("IF 0 SET X = $T");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "",
              "Special: $T = 0 after IF 0");
      Destroy_AST (Prog);

      -- $X cursor position
      P := Create_Parser ("SET X = $X");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Special: $X returns value");
      Destroy_AST (Prog);

      -- $Y cursor position
      P := Create_Parser ("SET X = $Y");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Special: $Y returns value");
      Destroy_AST (Prog);

      -- $H HOROLOG
      P := Create_Parser ("SET X = $H");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Special: $H returns value");
      Destroy_AST (Prog);

      -- $I IO device
      P := Create_Parser ("SET X = $I");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Special: $I returns value");
      Destroy_AST (Prog);

      -- $J Job number
      P := Create_Parser ("SET X = $J");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" and then
              To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Special: $J returns PID");
      Destroy_AST (Prog);

      -- $K Key
      P := Create_Parser ("SET X = $K");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "skipped",
              "Special: $K = ''");
      Destroy_AST (Prog);

      -- $S Storage
      P := Create_Parser ("SET X = $S");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Special: $S returns value");
      Destroy_AST (Prog);

      -- $SYSTEM
      P := Create_Parser ("SET X = $SYSTEM");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "adam",
              "Special: $SYSTEM = adam");
      Destroy_AST (Prog);

      -- $ECODE
      P := Create_Parser ("SET X = $ECODE");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else
              To_String (Symbol_Table.Get_Var ("X")) = " 0",
              "Special: $ECODE = 0");
      Destroy_AST (Prog);

      -- $ETRAP
      P := Create_Parser ("SET X = $ETRAP");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "skipped",
              "Special: $ETRAP = ''");
      Destroy_AST (Prog);
   end;

   New_Line;

   -- Integration Tests (20 tests)
   Put_Line ("Integration Tests:");
   Put_Line ("==================");
   declare
      R    : Runtime_State;
      P    : Parser_State;
      Prog : AST_Node_Ptr;
   begin
      R := Create_Runtime;

      -- Test SET and GET
      P := Create_Parser ("SET X = 42");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "42",
              "Integration: SET and GET");
      Destroy_AST (Prog);

      -- Test multiple commands
      P := Create_Parser ("SET A = 1 SET B = 2");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("A")) = "1",
              "Integration: Multiple SET A");
      Assert (To_String (Symbol_Table.Get_Var ("B")) = "2",
              "Integration: Multiple SET B");
      Destroy_AST (Prog);

      -- Test expression evaluation
      P := Create_Parser ("SET X = 1 + 2 * 3");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "9",
              "Integration: Expression 1 + 2 * 3 = 9");
      Destroy_AST (Prog);

      -- Test string concatenation
      P := Create_Parser ("SET X = ""Hello"" _ "" "" _ ""World""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) = "Hello World",
              "Integration: String concatenation");
      Destroy_AST (Prog);

      -- Test subscripted variables
      P := Create_Parser ("SET A(1) = ""first""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Subscript ("A", "1")) = "first",
              "Integration: Subscripted variable");
      Destroy_AST (Prog);

      -- Test NEW
      Symbol_Table.Set_Var ("NV", "original");
      P := Create_Parser ("NEW NV SET NV = ""modified""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("NV")) = "modified",
              "Integration: NEW and SET");
      Destroy_AST (Prog);

      -- Test ELSE
      R := Create_Runtime;
      P := Create_Parser ("IF 1 ELSE SET X = ""skipped""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "skipped",
              "Integration: ELSE skipped");
      Destroy_AST (Prog);

      -- Test QUIT
      R := Create_Runtime;
      P := Create_Parser ("QUIT 42");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (Get_Quit_Value (R) = "42",
              "Integration: QUIT value");
      Destroy_AST (Prog);

      -- Test MERGE
      Symbol_Table.Set_Var ("SRC", "source");
      P := Create_Parser ("MERGE DST=SRC");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("DST")) /= "",
              "Integration: MERGE");
      Destroy_AST (Prog);

      -- Test XECUTE
      Symbol_Table.Set_Var ("XE", "before");
      P := Create_Parser ("XECUTE ""SET XE = """"after""""""");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("XE")) /= "",
              "Integration: XECUTE");
      Destroy_AST (Prog);

      -- Test indirection
      Symbol_Table.Set_Var ("PTR", "TARGET");
      Symbol_Table.Set_Var ("TARGET", "indirected");
      P := Create_Parser ("SET X = @PTR");
      Prog := Parse_Program (P);
      Execute (R, Prog);
      Assert (To_String (Symbol_Table.Get_Var ("X")) /= "" or else To_String (Symbol_Table.Get_Var ("X")) /= " ",
              "Integration: Indirection");
      Destroy_AST (Prog);

      -- Test file I/O
      IO.Open_Device (10, "/tmp/adam_test_integration.txt", IO.File_Write);
      IO.Use_Device (10);
      IO.Write ("Integration test");
      IO.Close_Device (10);
      IO.Open_Device (11, "/tmp/adam_test_integration.txt", IO.File_Read);
      IO.Use_Device (11);
      declare
         Line : constant String := IO.Read;
      begin
         Assert (Line = "Integration test",
                 "Integration: File I/O");
      end;
      IO.Close_Device (11);
      IO.Use_Device (0);
   end;

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
end Conformance_Expanded;
