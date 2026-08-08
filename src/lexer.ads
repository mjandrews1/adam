-- Package: adam
-- File:    src/lexer.ads
-- Summary: MUMPS Lexer (Tokenization) specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

package Lexer is

   -- Token types
   type Token_Type is (
      -- Literals
      Tok_String,       -- "text"
      Tok_Number,       -- 123, 3.14
      Tok_Identifier,   -- variable names, tags

      -- Commands (all 22 MUMPS commands)
      Tok_BREAK, Tok_CLOSE, Tok_DO, Tok_ELSE, Tok_FOR,
      Tok_GOTO, Tok_HALT, Tok_HANG, Tok_IF, Tok_JOB,
      Tok_KILL, Tok_LOCK, Tok_MERGE, Tok_NEW, Tok_OPEN,
      Tok_QUIT, Tok_READ, Tok_SET, Tok_USE, Tok_VIEW,
      Tok_WRITE, Tok_XECUTE,

      -- Operators
      Tok_Plus,         -- +
      Tok_Minus,        -- -
      Tok_Star,         -- *
      Tok_Slash,        -- /
      Tok_Backslash,    -- \  (integer divide)
      Tok_Hash,         -- #
      Tok_StarStar,     -- **
      Tok_Equals,       -- =
      Tok_NotEquals,    -- '=
      Tok_Less,         -- <
      Tok_Greater,      -- >
      Tok_LessEquals,   -- <=
      Tok_GreaterEquals, -- >=
      Tok_Follows,      -- ]
      Tok_SortAfter,    -- ]]
      Tok_Contains,     -- [
      Tok_NotContains,  -- '[
      Tok_Matches,      -- ?
      Tok_And,          -- &
      Tok_Or,           -- !
      Tok_Not,          -- '
      Tok_Concat,       -- _
      Tok_AtSign,       -- @

      -- Delimiters
      Tok_LParen,       -- (
      Tok_RParen,       -- )
      Tok_Comma,        -- ,
      Tok_Colon,        -- :
      Tok_Semicolon,    -- ;

      -- Special
      Tok_Newline,
      Tok_EOF
   );

   -- Token record
   type Token is record
      Kind    : Token_Type;
      Value   : String (1 .. 256);
      Val_Len : Natural;
      Line    : Natural;
      Col     : Natural;
   end record;

   -- Lexer state
   type Lexer_State is private;

   -- Initialize lexer with source code
   function Create_Lexer (Source : String) return Lexer_State;

   -- Get next token
   function Next_Token (State : in out Lexer_State) return Token;

   -- Peek at current token without consuming
   function Peek_Token (State : Lexer_State) return Token;

   -- Check if more tokens available
   function Has_More (State : Lexer_State) return Boolean;

private

   type Lexer_State is record
      Source  : String (1 .. 100000);
      Src_Len : Natural;
      Pos     : Natural;
      Line    : Natural;
      Col     : Natural;
      Current : Token;
   end record;

end Lexer;
