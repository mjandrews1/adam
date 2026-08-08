-- Package: adam
-- File:    src/parser.ads
-- Summary: MUMPS Parser (AST Generation) specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Lexer;                  use Lexer;

package Parser is

   -- AST Node Types
   type Node_Kind is (
      -- Program structure
      N_Program,
      N_Line,
      N_Tag,

      -- Commands
      N_Set, N_Write, N_Read, N_Kill, N_Do, N_Quit,
      N_If, N_Else, N_For, N_Halt, N_Hang, N_Goto,
      N_Merge, N_New, N_Lock, N_Xecute, N_Use,
      N_Open, N_Close, N_View, N_Break, N_Job,

      -- Literals and variables
      N_String_Lit,
      N_Number_Lit,
      N_Variable,
      N_Global,
      N_Subscript,

      -- Binary operators (left op right)
      N_Add,            -- +
      N_Sub,            -- -
      N_Mul,            -- *
      N_Div,            -- /
      N_IntDiv,         -- \  (integer divide)
      N_Mod,            -- #
      N_Pow,            -- **
      N_Concat,         -- _
      N_Eql,            -- =
      N_Neql,           -- '=
      N_Lt,             -- <
      N_Gt,             -- >
      N_Lte,            -- <=
      N_Gte,            -- >=
      N_Follows,        -- ]
      N_SortsAfter,     -- ]]
      N_Contains,       -- [
      N_And,            -- &
      N_Or,             -- !

      -- Unary operators (op operand)
      N_UnaryMinus,     -- - (unary)
      N_UnaryPlus,      -- + (unary)
      N_Not,            -- '

      -- Function call
      N_Function_Call,  -- $FUNC(args)

      -- Special
      N_Null
   );

   -- AST Node
   type AST_Node;
   type AST_Node_Ptr is access AST_Node;

   type AST_Node is record
      Kind     : Node_Kind;
      Value    : Unbounded_String;
      Left     : AST_Node_Ptr;
      Right    : AST_Node_Ptr;
      Next     : AST_Node_Ptr;  -- For argument lists
      Line_Num : Natural;
   end record;

   -- Parser state
   type Parser_State is private;

   -- Initialize parser with source code
   function Create_Parser (Source : String) return Parser_State;

   -- Parse program and return AST
   function Parse_Program (State : in out Parser_State) return AST_Node_Ptr;

   -- Parse a single line
   function Parse_Line (State : in out Parser_State) return AST_Node_Ptr;

   -- Parse expression (entry point for expression parsing)
   function Parse_Expression (State : in out Parser_State) return AST_Node_Ptr;

   -- Destroy AST
   procedure Destroy_AST (Node : in out AST_Node_Ptr);

private

   type Parser_State is record
      Lex     : Lexer.Lexer_State;
      Current : Token;
   end record;

end Parser;
