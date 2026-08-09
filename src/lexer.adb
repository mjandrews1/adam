-- Package: adam
-- File:    src/lexer.adb
-- Summary: MUMPS Lexer (Tokenization) implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Characters.Handling; use Ada.Characters.Handling;

package body Lexer is

   function Create_Lexer (Source : String) return Lexer_State is
      State : Lexer_State;
   begin
      State.Source (1 .. Source'Length) := Source;
      State.Src_Len := Source'Length;
      State.Pos := 1;
      State.Line := 1;
      State.Col := 1;
      State.Current := (Tok_EOF, (others => ' '), 0, 0, 0);
      return State;
   end Create_Lexer;

   -- Check if character is a letter
   function Is_Alpha (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z') or else
             (C >= 'a' and then C <= 'z');
   end Is_Alpha;

   -- Check if character is a digit
   function Is_Digit (C : Character) return Boolean is
   begin
      return C >= '0' and then C <= '9';
   end Is_Digit;

   -- Check if character is alphanumeric
   function Is_Alnum (C : Character) return Boolean is
   begin
      return Is_Alpha (C) or else Is_Digit (C) or else C = '_';
   end Is_Alnum;

   -- Skip whitespace (not newlines)
   procedure Skip_Whitespace (State : in out Lexer_State) is
   begin
      while State.Pos <= State.Src_Len and then
        (State.Source (State.Pos) = ' ' or else
         State.Source (State.Pos) = ASCII.HT) loop
         State.Pos := State.Pos + 1;
         State.Col := State.Col + 1;
      end loop;
   end Skip_Whitespace;

   -- Read a string literal
   function Read_String (State : in out Lexer_State) return Token is
      Result : Token;
      Start  : Natural;
   begin
      Result.Kind := Tok_String;
      Result.Line := State.Line;
      Result.Col := State.Col;
      State.Pos := State.Pos + 1; -- Skip opening quote
      Start := State.Pos;
      while State.Pos <= State.Src_Len loop
         if State.Source (State.Pos) = '"' then
            -- Check for escaped quote
            if State.Pos + 1 <= State.Src_Len and then
              State.Source (State.Pos + 1) = '"' then
               State.Pos := State.Pos + 2;
            else
               exit;
            end if;
         else
            State.Pos := State.Pos + 1;
         end if;
      end loop;
      declare
         Len : constant Natural := State.Pos - Start;
      begin
         if Len > 256 then
            Result.Value (1 .. 256) := State.Source (Start .. Start + 255);
            Result.Val_Len := 256;
         else
            Result.Value (1 .. Len) := State.Source (Start .. Start + Len - 1);
            Result.Val_Len := Len;
         end if;
      end;
      State.Pos := State.Pos + 1; -- Skip closing quote
      return Result;
   end Read_String;

   -- Read a number
   function Read_Number (State : in out Lexer_State) return Token is
      Result   : Token;
      Start    : Natural;
      Has_Dot  : Boolean := False;
   begin
      Result.Kind := Tok_Number;
      Result.Line := State.Line;
      Result.Col := State.Col;
      Start := State.Pos;
      while State.Pos <= State.Src_Len and then
        (Is_Digit (State.Source (State.Pos)) or else
         (State.Source (State.Pos) = '.' and then not Has_Dot)) loop
         if State.Source (State.Pos) = '.' then
            Has_Dot := True;
         end if;
         State.Pos := State.Pos + 1;
      end loop;
      declare
         Len : constant Natural := State.Pos - Start;
      begin
         if Len > 256 then
            Result.Value (1 .. 256) := State.Source (Start .. Start + 255);
            Result.Val_Len := 256;
         else
            Result.Value (1 .. Len) := State.Source (Start .. Start + Len - 1);
            Result.Val_Len := Len;
         end if;
      end;
      return Result;
   end Read_Number;

   -- Read an identifier or command
   function Read_Identifier (State : in out Lexer_State) return Token is
      Result : Token;
      Start  : Natural;
      Word   : String (1 .. 20);
      WLen   : Natural := 0;
   begin
      Result.Line := State.Line;
      Result.Col := State.Col;
      Start := State.Pos;
      while State.Pos <= State.Src_Len and then Is_Alnum (State.Source (State.Pos)) loop
         State.Pos := State.Pos + 1;
      end loop;
      declare
         Len : constant Natural := State.Pos - Start;
      begin
         if Len > 256 then
            Result.Value (1 .. 256) := State.Source (Start .. Start + 255);
            Result.Val_Len := 256;
         else
            Result.Value (1 .. Len) := State.Source (Start .. Start + Len - 1);
            Result.Val_Len := Len;
         end if;
         -- Check if it's a command keyword
         if Len <= 20 then
            WLen := Len;
            Word (1 .. WLen) := State.Source (Start .. Start + Len - 1);
         end if;
      end;
      -- Map to command tokens (case-insensitive)
      if WLen = 1 then
         case Word (1) is
            when 'B' | 'b' => Result.Kind := Tok_BREAK;
            when 'C' | 'c' => Result.Kind := Tok_CLOSE;
            when 'D' | 'd' => Result.Kind := Tok_DO;
            when 'E' | 'e' => Result.Kind := Tok_ELSE;
            when 'F' | 'f' => Result.Kind := Tok_FOR;
            when 'G' | 'g' => Result.Kind := Tok_GOTO;
            when 'H' | 'h' => Result.Kind := Tok_HALT;
            when 'I' | 'i' => Result.Kind := Tok_IF;
            when 'J' | 'j' => Result.Kind := Tok_JOB;
            when 'K' | 'k' => Result.Kind := Tok_KILL;
            when 'L' | 'l' => Result.Kind := Tok_LOCK;
            when 'M' | 'm' => Result.Kind := Tok_MERGE;
            when 'N' | 'n' => Result.Kind := Tok_NEW;
            when 'O' | 'o' => Result.Kind := Tok_OPEN;
            when 'Q' | 'q' => Result.Kind := Tok_QUIT;
            when 'R' | 'r' => Result.Kind := Tok_READ;
            when 'S' | 's' => Result.Kind := Tok_SET;
            when 'U' | 'u' => Result.Kind := Tok_USE;
            when 'V' | 'v' => Result.Kind := Tok_VIEW;
            when 'W' | 'w' => Result.Kind := Tok_WRITE;
            when 'X' | 'x' => Result.Kind := Tok_XECUTE;
            when others => Result.Kind := Tok_Identifier;
         end case;
      elsif WLen > 1 then
         -- Check for full command names
         if Word (1 .. WLen) = "BREAK" or else Word (1 .. WLen) = "break" then
            Result.Kind := Tok_BREAK;
         elsif Word (1 .. WLen) = "CLOSE" or else Word (1 .. WLen) = "close" then
            Result.Kind := Tok_CLOSE;
         elsif Word (1 .. WLen) = "DO" or else Word (1 .. WLen) = "do" then
            Result.Kind := Tok_DO;
         elsif Word (1 .. WLen) = "ELSE" or else Word (1 .. WLen) = "else" then
            Result.Kind := Tok_ELSE;
         elsif Word (1 .. WLen) = "FOR" or else Word (1 .. WLen) = "for" then
            Result.Kind := Tok_FOR;
         elsif Word (1 .. WLen) = "GOTO" or else Word (1 .. WLen) = "goto" then
            Result.Kind := Tok_GOTO;
         elsif Word (1 .. WLen) = "HALT" or else Word (1 .. WLen) = "halt" then
            Result.Kind := Tok_HALT;
         elsif Word (1 .. WLen) = "HANG" or else Word (1 .. WLen) = "hang" then
            Result.Kind := Tok_HANG;
         elsif Word (1 .. WLen) = "IF" or else Word (1 .. WLen) = "if" then
            Result.Kind := Tok_IF;
         elsif Word (1 .. WLen) = "JOB" or else Word (1 .. WLen) = "job" then
            Result.Kind := Tok_JOB;
         elsif Word (1 .. WLen) = "KILL" or else Word (1 .. WLen) = "kill" then
            Result.Kind := Tok_KILL;
         elsif Word (1 .. WLen) = "LOCK" or else Word (1 .. WLen) = "lock" then
            Result.Kind := Tok_LOCK;
         elsif Word (1 .. WLen) = "MERGE" or else Word (1 .. WLen) = "merge" then
            Result.Kind := Tok_MERGE;
         elsif Word (1 .. WLen) = "NEW" or else Word (1 .. WLen) = "new" then
            Result.Kind := Tok_NEW;
         elsif Word (1 .. WLen) = "OPEN" or else Word (1 .. WLen) = "open" then
            Result.Kind := Tok_OPEN;
         elsif Word (1 .. WLen) = "QUIT" or else Word (1 .. WLen) = "quit" then
            Result.Kind := Tok_QUIT;
         elsif Word (1 .. WLen) = "READ" or else Word (1 .. WLen) = "read" then
            Result.Kind := Tok_READ;
         elsif Word (1 .. WLen) = "SET" or else Word (1 .. WLen) = "set" then
            Result.Kind := Tok_SET;
         elsif Word (1 .. WLen) = "USE" or else Word (1 .. WLen) = "use" then
            Result.Kind := Tok_USE;
         elsif Word (1 .. WLen) = "VIEW" or else Word (1 .. WLen) = "view" then
            Result.Kind := Tok_VIEW;
         elsif Word (1 .. WLen) = "WRITE" or else Word (1 .. WLen) = "write" then
            Result.Kind := Tok_WRITE;
         elsif Word (1 .. WLen) = "XECUTE" or else Word (1 .. WLen) = "xecute" then
            Result.Kind := Tok_XECUTE;
         else
            Result.Kind := Tok_Identifier;
         end if;
      else
         Result.Kind := Tok_Identifier;
      end if;
      return Result;
   end Read_Identifier;

   function Next_Token (State : in out Lexer_State) return Token is
      Result : Token;
      C      : Character;
   begin
      Skip_Whitespace (State);
      if State.Pos > State.Src_Len then
         Result := (Tok_EOF, (others => ' '), 0, State.Line, State.Col);
         State.Current := Result;
         return Result;
      end if;
      C := State.Source (State.Pos);
      -- Handle newlines
      if C = ASCII.LF then
         Result := (Tok_Newline, (1 => ASCII.LF, others => ' '), 1,
                    State.Line, State.Col);
         State.Pos := State.Pos + 1;
         State.Line := State.Line + 1;
         State.Col := 1;
         State.Current := Result;
         return Result;
      end if;
      -- Handle string literals
      if C = '"' then
         Result := Read_String (State);
         State.Current := Result;
         return Result;
      end if;
      -- Handle numbers
      if Is_Digit (C) then
         Result := Read_Number (State);
         State.Current := Result;
         return Result;
      end if;
      -- Handle identifiers and commands
      if Is_Alpha (C) or else C = '^' then
         Result := Read_Identifier (State);
         State.Current := Result;
         return Result;
      end if;
      -- Handle operators and delimiters
      Result.Line := State.Line;
      Result.Col := State.Col;
      case C is
         when '+' => Result := (Tok_Plus, (1 => '+', others => ' '), 1, State.Line, State.Col);
         when '-' => Result := (Tok_Minus, (1 => '-', others => ' '), 1, State.Line, State.Col);
         when '*' =>
            if State.Pos + 1 <= State.Src_Len and then State.Source (State.Pos + 1) = '*' then
               Result := (Tok_StarStar, (1 => '*', 2 => '*', others => ' '), 2, State.Line, State.Col);
               State.Pos := State.Pos + 2;
               State.Col := State.Col + 2;
               State.Current := Result;
               return Result;
            else
               Result := (Tok_Star, (1 => '*', others => ' '), 1, State.Line, State.Col);
            end if;
         when '/' => Result := (Tok_Slash, (1 => '/', others => ' '), 1, State.Line, State.Col);
         when '\' => Result := (Tok_Backslash, (1 => '\', others => ' '), 1, State.Line, State.Col);
         when '#' => Result := (Tok_Hash, (1 => '#', others => ' '), 1, State.Line, State.Col);
         when '=' => Result := (Tok_Equals, (1 => '=', others => ' '), 1, State.Line, State.Col);
         when '<' =>
            if State.Pos + 1 <= State.Src_Len and then State.Source (State.Pos + 1) = '=' then
               Result := (Tok_LessEquals, (1 => '<', 2 => '=', others => ' '), 2, State.Line, State.Col);
               State.Pos := State.Pos + 2;
               State.Col := State.Col + 2;
               State.Current := Result;
               return Result;
            else
               Result := (Tok_Less, (1 => '<', others => ' '), 1, State.Line, State.Col);
            end if;
         when '>' =>
            if State.Pos + 1 <= State.Src_Len and then State.Source (State.Pos + 1) = '=' then
               Result := (Tok_GreaterEquals, (1 => '>', 2 => '=', others => ' '), 2, State.Line, State.Col);
               State.Pos := State.Pos + 2;
               State.Col := State.Col + 2;
               State.Current := Result;
               return Result;
            else
               Result := (Tok_Greater, (1 => '>', others => ' '), 1, State.Line, State.Col);
            end if;
         when ']' =>
            if State.Pos + 1 <= State.Src_Len and then State.Source (State.Pos + 1) = ']' then
               Result := (Tok_SortAfter, (1 => ']', 2 => ']', others => ' '), 2, State.Line, State.Col);
               State.Pos := State.Pos + 2;
               State.Col := State.Col + 2;
               State.Current := Result;
               return Result;
            else
               Result := (Tok_Follows, (1 => ']', others => ' '), 1, State.Line, State.Col);
            end if;
         when '[' => Result := (Tok_Contains, (1 => '[', others => ' '), 1, State.Line, State.Col);
         when '?' => Result := (Tok_Matches, (1 => '?', others => ' '), 1, State.Line, State.Col);
         when '&' => Result := (Tok_And, (1 => '&', others => ' '), 1, State.Line, State.Col);
         when '!' => Result := (Tok_Or, (1 => '!', others => ' '), 1, State.Line, State.Col);
         when '_' => Result := (Tok_Concat, (1 => '_', others => ' '), 1, State.Line, State.Col);
         when '@' => Result := (Tok_AtSign, (1 => '@', others => ' '), 1, State.Line, State.Col);
         when '$' => Result := (Tok_Dollar, (1 => '$', others => ' '), 1, State.Line, State.Col);
         when '(' => Result := (Tok_LParen, (1 => '(', others => ' '), 1, State.Line, State.Col);
         when ')' => Result := (Tok_RParen, (1 => ')', others => ' '), 1, State.Line, State.Col);
         when ',' => Result := (Tok_Comma, (1 => ',', others => ' '), 1, State.Line, State.Col);
         when ':' => Result := (Tok_Colon, (1 => ':', others => ' '), 1, State.Line, State.Col);
         when ';' => Result := (Tok_Semicolon, (1 => ';', others => ' '), 1, State.Line, State.Col);
         when ''' =>
            if State.Pos + 1 <= State.Src_Len then
               case State.Source (State.Pos + 1) is
                  when '=' =>
                     Result := (Tok_NotEquals, (1 => ''', 2 => '=', others => ' '), 2, State.Line, State.Col);
                     State.Pos := State.Pos + 2;
                     State.Col := State.Col + 2;
                     State.Current := Result;
                     return Result;
                  when '<' =>
                     Result := (Tok_LessEquals, (1 => ''', 2 => '<', others => ' '), 2, State.Line, State.Col);
                     State.Pos := State.Pos + 2;
                     State.Col := State.Col + 2;
                     State.Current := Result;
                     return Result;
                  when '>' =>
                     Result := (Tok_GreaterEquals, (1 => ''', 2 => '>', others => ' '), 2, State.Line, State.Col);
                     State.Pos := State.Pos + 2;
                     State.Col := State.Col + 2;
                     State.Current := Result;
                     return Result;
                  when '[' =>
                     Result := (Tok_NotContains, (1 => ''', 2 => '[', others => ' '), 2, State.Line, State.Col);
                     State.Pos := State.Pos + 2;
                     State.Col := State.Col + 2;
                     State.Current := Result;
                     return Result;
                  when others =>
                     Result := (Tok_Not, (1 => ''', others => ' '), 1, State.Line, State.Col);
               end case;
            else
               Result := (Tok_Not, (1 => ''', others => ' '), 1, State.Line, State.Col);
            end if;
         when others =>
            Result := (Tok_EOF, (others => ' '), 0, State.Line, State.Col);
      end case;
      State.Pos := State.Pos + 1;
      State.Col := State.Col + 1;
      State.Current := Result;
      return Result;
   end Next_Token;

   function Peek_Token (State : Lexer_State) return Token is
   begin
      return State.Current;
   end Peek_Token;

   function Has_More (State : Lexer_State) return Boolean is
   begin
      return State.Pos <= State.Src_Len;
   end Has_More;

end Lexer;
