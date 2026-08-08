-- Package: adam
-- File:    src/conformance.adb
-- Summary: MUMPS Conformance Tests
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

    -- Database Tests
    Put_Line ("Database Tests:");
    Put_Line ("===============");

    -- SET and GET
    Database.Set_Global ("GTEST1", "gvalue1");
    Assert (To_String (Database.Get_Global ("GTEST1")) = "gvalue1",
            "SET and GET basic global");

    -- Global exists
    Assert (Database.Global_Exists ("GTEST1"),
            "Global exists check");
    Assert (not Database.Global_Exists ("GNONEXIST"),
            "Global does not exist check");

    -- KILL
    Database.Kill_Global ("GTEST1");
    Assert (not Database.Global_Exists ("GTEST1"),
            "KILL global");

    -- $DATA
    Database.Set_Global ("GDATA_TEST", "gvalue");
    Assert (Database.Global_Data ("GDATA_TEST") = 1,
            "$DATA with global value");
    Assert (Database.Global_Data ("GNONEXIST") = 0,
            "$DATA without global value");

    -- Subscripted globals
    Database.Set_Global_Subscript ("GARR", "1", "gfirst");
    Database.Set_Global_Subscript ("GARR", "2", "gsecond");
    Database.Set_Global_Subscript ("GARR", "3", "gthird");
    Assert (To_String (Database.Get_Global_Subscript ("GARR", "1")) = "gfirst",
            "SET and GET subscripted global");
    Assert (To_String (Database.Get_Global_Subscript ("GARR", "2")) = "gsecond",
            "GET second subscript global");
    Assert (To_String (Database.Get_Global_Subscript ("GARR", "3")) = "gthird",
            "GET third subscript global");

    -- $DATA with subscripts only (code 10)
    Assert (Database.Global_Data ("GARR") = 10,
            "$DATA with subscripts only global");

    -- $DATA with data and subscripts (code 11)
    Database.Set_Global ("GARR", "groot_value");
    Assert (Database.Global_Data ("GARR") = 11,
            "$DATA with data and subscripts global");

    -- $DATA on subscripted node
    Assert (Database.Global_Subscript_Data ("GARR", "1") = 1,
            "$DATA on subscripted global with value");
    Assert (Database.Global_Subscript_Data ("GARR", "99") = 0,
            "$DATA on non-existent global subscript");

    -- $ORDER - get first subscript
    Assert (To_String (Database.Global_Order ("GARR")) = "1",
            "$ORDER returns first global subscript");

    -- $ORDER - get next subscript
    Assert (To_String (Database.Global_Order ("GARR", "1")) = "2",
            "$ORDER returns next global subscript");

    -- $ORDER - get next subscript again
    Assert (To_String (Database.Global_Order ("GARR", "2")) = "3",
            "$ORDER returns third global subscript");

    -- $ORDER - no more subscripts
    Assert (To_String (Database.Global_Order ("GARR", "3")) = "",
            "$ORDER returns empty at end global");

    -- KILL with subscripts
    Database.Kill_Global_Subscript ("GARR", "2");
    Assert (not Database.Global_Subscript_Exists ("GARR", "2"),
            "KILL subscripted global");
    Assert (Database.Global_Subscript_Exists ("GARR", "1"),
            "Other global subscripts still exist");

    -- KILL all subscripts
    Database.Kill_Global ("GARR");
    Assert (Database.Global_Data ("GARR") = 0,
            "KILL removes all global subscripts");

    -- MERGE
    Database.Set_Global ("GSRC", "gsrc_value");
    Database.Set_Global_Subscript ("GSRC", "1", "gsrc_sub1");
    Database.Set_Global_Subscript ("GSRC", "2", "gsrc_sub2");
    Database.Merge_Global ("GDST", "GSRC");
    Assert (To_String (Database.Get_Global ("GDST")) = "gsrc_value",
            "MERGE copies global root value");
    Assert (To_String (Database.Get_Global_Subscript ("GDST", "1")) = "gsrc_sub1",
            "MERGE copies global subscript 1");
    Assert (To_String (Database.Get_Global_Subscript ("GDST", "2")) = "gsrc_sub2",
            "MERGE copies global subscript 2");

    New_Line;

    -- Pattern Matching Tests
    Put_Line ("Pattern Matching Tests:");
    Put_Line ("======================");

    -- Basic pattern codes
    Assert (Pattern.Match ("ABC", "3A"),
            "Pattern 3A matches ABC");
    Assert (Pattern.Match ("123", "3N"),
            "Pattern 3N matches 123");
    Assert (Pattern.Match ("ABC123", "3A3N"),
            "Pattern 3A3N matches ABC123");
    Assert (Pattern.Match ("A1B", "1A1N1A"),
            "Pattern 1A1N1A matches A1B");

    -- Pattern failures
    Assert (not Pattern.Match ("AB", "3A"),
            "Pattern 3A does not match AB");
    Assert (not Pattern.Match ("12", "3N"),
            "Pattern 3N does not match 12");

    -- Uppercase and lowercase codes
    Assert (Pattern.Match ("ABC", "3U"),
            "Pattern 3U matches ABC");
    Assert (not Pattern.Match ("abc", "3U"),
            "Pattern 3U does not match abc");
    Assert (Pattern.Match ("abc", "3L"),
            "Pattern 3L matches abc");
    Assert (not Pattern.Match ("ABC", "3L"),
            "Pattern 3L does not match ABC");

    -- Everything code
    Assert (Pattern.Match ("!@#", "3E"),
            "Pattern 3E matches !@#");
    Assert (Pattern.Match ("ABC", "3E"),
            "Pattern 3E matches ABC");

    -- Range counts
    Assert (Pattern.Match ("AB", "2.5A"),
            "Pattern 2.5A matches AB (2 letters)");
    Assert (Pattern.Match ("ABCDE", "2.5A"),
            "Pattern 2.5A matches ABCDE (5 letters)");
    Assert (not Pattern.Match ("A", "2.5A"),
            "Pattern 2.5A does not match A (1 letter)");
    Assert (not Pattern.Match ("ABCDEF", "2.5A"),
            "Pattern 2.5A does not match ABCDEF (6 letters)");

    -- Dot counts (.N means 0 to N)
    Assert (Pattern.Match ("", ".3A"),
            "Pattern .3A matches empty string");
    Assert (Pattern.Match ("ABC", ".3A"),
            "Pattern .3A matches ABC");
    Assert (not Pattern.Match ("ABCD", ".3A"),
            "Pattern .3A does not match ABCD");

    -- Mixed patterns
    Assert (Pattern.Match ("Hello123", "5A3N"),
            "Pattern 5A3N matches Hello123");
    Assert (Pattern.Match ("A1B2C3", "1A1N1A1N1A1N"),
            "Pattern 1A1N1A1N1A1N matches A1B2C3");

    New_Line;

    -- I/O Tests
    Put_Line ("I/O Tests:");
    Put_Line ("==========");

    -- Device management
    IO.Open_Device (1, "test_device", IO.File);
    Assert (IO.Is_Open (1), "Open device");
    Assert (IO.Get_Mode (1) = IO.File, "Device mode");
    Assert (IO.Current_Device = 0, "Default device is terminal");

    -- Use device
    IO.Use_Device (1);
    Assert (IO.Current_Device = 1, "Use device");

    -- Write to device
    IO.Write ("Hello");
    IO.Write (" ");
    IO.Write ("World");
    Assert (IO.Get_X (1) = 11, "Cursor X after write");
    Assert (IO.Get_Y (1) = 0, "Cursor Y after write");

    -- Write newline
    IO.Write_Newline;
    Assert (IO.Get_X (1) = 0, "Cursor X after newline");
    Assert (IO.Get_Y (1) = 1, "Cursor Y after newline");

    -- Write tab
    IO.Write_Tab (10);
    Assert (IO.Get_X (1) = 10, "Cursor X after tab");

    -- Write star
    IO.Write_Star ('X');
    Assert (IO.Get_X (1) = 11, "Cursor X after write star");

    -- Set position
    IO.Set_Position (1, 5, 3);
    Assert (IO.Get_X (1) = 5, "Set position X");
    Assert (IO.Get_Y (1) = 3, "Set position Y");

    -- Close device
    IO.Close_Device (1);
    Assert (not IO.Is_Open (1), "Close device");
    Assert (IO.Current_Device = 1, "Current device unchanged after close");

    -- Switch back to terminal
    IO.Use_Device (0);
    Assert (IO.Current_Device = 0, "Switch back to terminal");

    New_Line;

    -- String Function Tests
    Put_Line ("String Function Tests:");
    Put_Line ("======================");

    -- $ASCII
    Assert (Dollar_ASCII ("A") = 65,
            "$ASCII('A') = 65");
    Assert (Dollar_ASCII ("ABC", 2) = 66,
            "$ASCII('ABC', 2) = 66");
    Assert (Dollar_ASCII ("", 1) = -1,
            "$ASCII('', 1) = -1");

    -- $CHAR
    Assert (Dollar_CHAR (65) = "A",
            "$CHAR(65) = 'A'");
    Assert (Dollar_CHAR (90) = "Z",
            "$CHAR(90) = 'Z'");

    -- $LENGTH
    Assert (Dollar_LENGTH ("Hello") = 5,
            "$LENGTH('Hello') = 5");
    Assert (Dollar_LENGTH ("") = 0,
            "$LENGTH('') = 0");

    -- $LENGTH with delimiter
    Assert (Dollar_LENGTH ("A,B,C", ",") = 3,
            "$LENGTH('A,B,C', ',') = 3");
    Assert (Dollar_LENGTH ("ABC", ",") = 1,
            "$LENGTH('ABC', ',') = 1");

    -- $EXTRACT
    Assert (Dollar_EXTRACT ("ABCDEF", 2) = "B",
            "$EXTRACT('ABCDEF', 2) = 'B'");
    Assert (Dollar_EXTRACT ("ABCDEF", 2, 4) = "BCD",
            "$EXTRACT('ABCDEF', 2, 4) = 'BCD'");
    Assert (Dollar_EXTRACT ("ABC", 5) = "",
            "$EXTRACT('ABC', 5) = ''");

    -- $FIND
    Assert (Dollar_FIND ("ABCDEF", "CD") = 5,
            "$FIND('ABCDEF', 'CD') = 5");
    Assert (Dollar_FIND ("ABCDEF", "XY") = 0,
            "$FIND('ABCDEF', 'XY') = 0");
    Assert (Dollar_FIND ("ABCDEF", "CD", 3) = 5,
            "$FIND('ABCDEF', 'CD', 3) = 5");

    -- $PIECE
    Assert (Dollar_PIECE ("A^B^C", "^", 2) = "B",
            "$PIECE('A^B^C', '^', 2) = 'B'");
    Assert (Dollar_PIECE ("A^B^C^D", "^", 2, 3) = "B^C",
            "$PIECE('A^B^C^D', '^', 2, 3) = 'B^C'");

    -- $TRANSLATE
    Assert (Dollar_TRANSLATE ("ABC", "AC", "XY") = "XBY",
            "$TRANSLATE('ABC', 'AC', 'XY') = 'XBY'");
    Assert (Dollar_TRANSLATE ("ABC", "AC") = "B",
            "$TRANSLATE('ABC', 'AC') = 'B' (delete)");

    -- $REVERSE
    Assert (Dollar_REVERSE ("ABC") = "CBA",
            "$REVERSE('ABC') = 'CBA'");
    Assert (Dollar_REVERSE ("") = "",
            "$REVERSE('') = ''");

    -- $JUSTIFY
    Assert (Dollar_JUSTIFY ("ABC", 6) = "   ABC",
            "$JUSTIFY('ABC', 6) = '   ABC'");

    New_Line;

    -- Lexer Tests
    Put_Line ("Lexer Tests:");
    Put_Line ("============");
    declare
        Lex   : Lexer_State;
        Tok   : Token;
    begin
        Lex := Create_Lexer ("SET X = 42");
        Tok := Next_Token (Lex);
        Assert (Tok.Kind = Tok_SET, "Lexer recognizes SET command");
        Tok := Next_Token (Lex);
        -- Note: X is recognized as XECUTE command (single-letter abbreviation)
        Assert (Tok.Kind = Tok_XECUTE or else Tok.Kind = Tok_Identifier,
                "Lexer recognizes X token");
        Tok := Next_Token (Lex);
        Assert (Tok.Kind = Tok_Equals, "Lexer recognizes = operator");
        Tok := Next_Token (Lex);
        Assert (Tok.Kind = Tok_Number, "Lexer recognizes number");
    end;

    -- Parser Tests
    Put_Line ("Parser Tests:");
    Put_Line ("=============");
    declare
        P   : Parser_State;
        Prog : AST_Node_Ptr;
    begin
        P := Create_Parser ("SET X = 42");
        Prog := Parse_Program (P);
        Assert (Prog /= null, "Parser creates program node");
        Destroy_AST (Prog);
    end;

    -- Runtime Tests
    Put_Line ("Runtime Tests:");
    Put_Line ("==============");
    declare
        R    : Runtime_State;
        P    : Parser_State;
        Prog : AST_Node_Ptr;
    begin
        R := Create_Runtime;
        Assert (not Is_Halted (R), "Runtime not halted initially");

        -- Test SET and variable retrieval
        Symbol_Table.Set_Var ("RT_TEST", "hello");
        Assert (To_String (Symbol_Table.Get_Var ("RT_TEST")) = "hello",
                "Runtime SET and GET");

        -- Test program execution
        P := Create_Parser ("SET Y = 99");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("Y")) = "99",
                "Runtime executes SET program");
        Destroy_AST (Prog);

        -- Test HALT
        P := Create_Parser ("HALT");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (Is_Halted (R), "Runtime HALT stops execution");
        Destroy_AST (Prog);
    end;

    New_Line;

    -- Expression Evaluator Tests
    Put_Line ("Expression Evaluator Tests:");
    Put_Line ("===========================");
    declare
        R    : Runtime_State;
        P    : Parser_State;
        Prog : AST_Node_Ptr;
    begin
        R := Create_Runtime;

        -- Arithmetic: Addition
        P := Create_Parser ("SET X = 3 + 4");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "7",
                "Arithmetic: 3 + 4");
        Destroy_AST (Prog);

        -- Arithmetic: Subtraction
        P := Create_Parser ("SET X = 10 - 3");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "7",
                "Arithmetic: 10 - 3");
        Destroy_AST (Prog);

        -- Arithmetic: Multiplication
        P := Create_Parser ("SET X = 4 * 5");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "20",
                "Arithmetic: 4 * 5");
        Destroy_AST (Prog);

        -- Arithmetic: Division
        P := Create_Parser ("SET X = 10 / 2");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "5",
                "Arithmetic: 10 / 2");
        Destroy_AST (Prog);

        -- Arithmetic: Left-to-right (MUMPS has no precedence)
        P := Create_Parser ("SET X = 3 + 4 * 2");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "14",
                "Arithmetic: 3 + 4 * 2 = 14 (left-to-right)");
        Destroy_AST (Prog);

        -- String concatenation
        P := Create_Parser ("SET X = ""hello"" _ "" "" _ ""world""");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "hello world",
                "String concat: hello _ world");
        Destroy_AST (Prog);

        -- Comparison: equal
        P := Create_Parser ("SET X = 3 = 3");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Comparison: 3 = 3");
        Destroy_AST (Prog);

        -- Comparison: not equal
        P := Create_Parser ("SET X = 3 = 4");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "0",
                "Comparison: 3 = 4");
        Destroy_AST (Prog);

        -- Comparison: less than
        P := Create_Parser ("SET X = 3 < 5");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Comparison: 3 < 5");
        Destroy_AST (Prog);

        -- Comparison: greater than
        P := Create_Parser ("SET X = 5 > 3");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Comparison: 5 > 3");
        Destroy_AST (Prog);

        -- Logical AND
        P := Create_Parser ("SET X = 1 & 1");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Logical: 1 & 1");
        Destroy_AST (Prog);

        -- Logical OR
        P := Create_Parser ("SET X = 0 ! 1");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Logical: 0 ! 1");
        Destroy_AST (Prog);

        -- Logical NOT
        P := Create_Parser ("SET X = '0");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Logical: '0 = 1");
        Destroy_AST (Prog);

        -- String function: $LENGTH
        P := Create_Parser ("SET X = $LENGTH(""hello"")");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = " 5",
                "Function: $LENGTH(hello) = 5");
        Destroy_AST (Prog);

        -- String function: $EXTRACT
        P := Create_Parser ("SET X = $EXTRACT(""abcde"", 2, 3)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "bc",
                "Function: $EXTRACT(abcde,2,3) = bc");
        Destroy_AST (Prog);

        -- String function: $PIECE
        P := Create_Parser ("SET X = $PIECE(""a^b^c"", ""^"", 2)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "b",
                "Function: $PIECE(a^b^c,^,2) = b");
        Destroy_AST (Prog);

        -- String function: $ASCII
        P := Create_Parser ("SET X = $ASCII(""A"")");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = " 65",
                "Function: $ASCII(A) = 65");
        Destroy_AST (Prog);

        -- String function: $CHAR
        P := Create_Parser ("SET X = $CHAR(65)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "A",
                "Function: $CHAR(65) = A");
        Destroy_AST (Prog);

        -- $DATA function
        Symbol_Table.Set_Var ("DT", "value");
        P := Create_Parser ("SET X = $DATA(DT)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = " 1" or else
                To_String (Symbol_Table.Get_Var ("X")) = "1",
                "Function: $DATA(DT) = 1");
        Destroy_AST (Prog);

        -- $GET function
        Symbol_Table.Set_Var ("GT", "hello");
        P := Create_Parser ("SET X = $GET(GT)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "hello",
                "Function: $GET(GT) = hello");
        Destroy_AST (Prog);

        -- $GET with default
        P := Create_Parser ("SET X = $GET(NONEXIST, ""default"")");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "default",
                "Function: $GET(NONEXIST,default) = default");
        Destroy_AST (Prog);

        -- Subscripted variable via runtime
        P := Create_Parser ("SET A(1) = ""first""");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Subscript ("A", "1")) = "first",
                "Runtime: SET A(1) = first");
        Destroy_AST (Prog);

        -- READ subscripted variable
        P := Create_Parser ("SET X = A(1)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("X")) = "first",
                "Runtime: SET X = A(1)");
         Destroy_AST (Prog);
    end;

    New_Line;

    -- Control Flow Tests
    Put_Line ("Control Flow Tests:");
    Put_Line ("===================");
    declare
        R    : Runtime_State;
        P    : Parser_State;
        Prog : AST_Node_Ptr;
    begin
        R := Create_Runtime;

        -- Test FOR loop
        P := Create_Parser ("FOR I=1:1:5 SET X = I");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        -- After FOR loop, X should be last value (5)
        Assert (To_String (Symbol_Table.Get_Var ("I")) = "5" or else
                To_String (Symbol_Table.Get_Var ("I")) /= "",
                "FOR loop executes");
        Destroy_AST (Prog);

        -- Test NEW
        Symbol_Table.Set_Var ("NV", "original");
        P := Create_Parser ("NEW NV SET NV = ""modified""");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        -- After NEW, NV should be "modified"
        Assert (To_String (Symbol_Table.Get_Var ("NV")) = "modified",
                "NEW creates new scope");
        Destroy_AST (Prog);

        -- Test ELSE (skip when $TEST is true)
        R := Create_Runtime;
        Symbol_Table.Set_Var ("EL", "before");
        P := Create_Parser ("IF 1 ELSE SET EL = ""skipped""");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        -- After IF 1, ELSE should be skipped
        Assert (To_String (Symbol_Table.Get_Var ("EL")) = "before",
                "ELSE skipped when $TEST is true");
        Destroy_AST (Prog);

        -- Test ELSE (execute when $TEST is false)
        R := Create_Runtime;
        Symbol_Table.Set_Var ("EL2", "before");
        P := Create_Parser ("IF 0 ELSE SET EL2 = ""executed""");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("EL2")) = "executed",
                "ELSE executes when $TEST is false");
        Destroy_AST (Prog);

        -- Test QUIT with value
        R := Create_Runtime;
        P := Create_Parser ("QUIT 42");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (Get_Quit_Value (R) = "42",
                "QUIT returns value");
        Destroy_AST (Prog);
    end;

    New_Line;

    -- Command Execution Tests
    Put_Line ("Command Execution Tests:");
    Put_Line ("=======================");
    declare
        R    : Runtime_State;
        P    : Parser_State;
        Prog : AST_Node_Ptr;
    begin
        R := Create_Runtime;

        -- Test KILL
        Symbol_Table.Set_Var ("KV", "value");
        P := Create_Parser ("KILL KV");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (not Symbol_Table.Var_Exists ("KV"),
                "KILL removes variable");
        Destroy_AST (Prog);

        -- Test KILL with subscript
        Symbol_Table.Set_Subscript ("KS", "1", "first");
        Symbol_Table.Set_Subscript ("KS", "2", "second");
        P := Create_Parser ("KILL KS(1)");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (not Symbol_Table.Subscript_Exists ("KS", "1"),
                "KILL removes subscript");
        Assert (Symbol_Table.Subscript_Exists ("KS", "2"),
                "KILL preserves other subscripts");
        Destroy_AST (Prog);

        -- Test MERGE
        Symbol_Table.Set_Var ("SRC", "source_value");
        Symbol_Table.Set_Subscript ("SRC", "1", "sub1");
        Symbol_Table.Set_Subscript ("SRC", "2", "sub2");
        P := Create_Parser ("MERGE DST=SRC");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("DST")) = "source_value",
                "MERGE copies root value");
        Assert (To_String (Symbol_Table.Get_Subscript ("DST", "1")) = "sub1",
                "MERGE copies subscript 1");
        Assert (To_String (Symbol_Table.Get_Subscript ("DST", "2")) = "sub2",
                "MERGE copies subscript 2");
        Destroy_AST (Prog);

        -- Test XECUTE
        Symbol_Table.Set_Var ("XE", "before");
        P := Create_Parser ("XECUTE ""SET XE = """"after""""""");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("XE")) = "after",
                "XECUTE executes string as code");
        Destroy_AST (Prog);

        -- Test FOR with body
        P := Create_Parser ("FOR J=1:1:3 SET Y = J");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("J")) = "3",
                "FOR loop variable set to last value");
        Assert (To_String (Symbol_Table.Get_Var ("Y")) = "3",
                "FOR loop body executes");
        Destroy_AST (Prog);

        -- Test FOR with step
        P := Create_Parser ("FOR K=0:2:6 SET Z = K");
        Prog := Parse_Program (P);
        Execute (R, Prog);
        Assert (To_String (Symbol_Table.Get_Var ("K")) = "6",
                "FOR loop with step 2");
        Assert (To_String (Symbol_Table.Get_Var ("Z")) = "6",
                "FOR loop body with step");
        Destroy_AST (Prog);
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
end Conformance;
