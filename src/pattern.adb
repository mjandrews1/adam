-- Package: adam
-- File:    src/pattern.adb
-- Summary: MUMPS Pattern Matching implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

package body Pattern is

   -- Check if character is a letter (A-Z, a-z)
   function Is_Alpha (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z') or else
             (C >= 'a' and then C <= 'z');
   end Is_Alpha;

   -- Check if character is a digit (0-9)
   function Is_Digit (C : Character) return Boolean is
   begin
      return C >= '0' and then C <= '9';
   end Is_Digit;

   -- Check if character is uppercase
   function Is_Upper (C : Character) return Boolean is
   begin
      return C >= 'A' and then C <= 'Z';
   end Is_Upper;

   -- Check if character is lowercase
   function Is_Lower (C : Character) return Boolean is
   begin
      return C >= 'a' and then C <= 'z';
   end Is_Lower;

   -- Check if character is punctuation
   function Is_Punct (C : Character) return Boolean is
   begin
      case C is
         when '!' | '"' | '#' | '$' | '%' | '&' | ''' | '(' |
              ')' | '*' | '+' | ',' | '-' | '.' | '/' | ':' |
              ';' | '<' | '=' | '>' | '?' | '@' | '[' | '\' |
              ']' | '^' | '_' | '`' | '{' | '|' | '}' | '~' =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Punct;

   -- Check if character is a control character
   function Is_Control (C : Character) return Boolean is
   begin
      return Character'Pos (C) < 32 or else Character'Pos (C) = 127;
   end Is_Control;

   -- Check if character matches a pattern code
   function Matches_Code (C : Character; Code : Character) return Boolean is
   begin
      case Code is
         when 'A' => return Is_Alpha (C);
         when 'N' => return Is_Digit (C);
         when 'E' => return True;
         when 'U' => return Is_Upper (C);
         when 'L' => return Is_Lower (C);
         when 'P' => return Is_Punct (C);
         when 'C' => return Is_Control (C);
         when others => return False;
      end case;
   end Matches_Code;

   -- Parse a count from pattern string
   -- Returns: min_count, max_count, new position
   procedure Parse_Count (Pat      : String;
                          Pos      : in out Natural;
                          Min_Count : out Natural;
                          Max_Count : out Natural) is
      Has_Dot : Boolean := False;
   begin
      Min_Count := 0;
      Max_Count := 0;

      -- Parse first number (or dot for .N)
      if Pos <= Pat'Length and then Pat (Pos) = '.' then
         Has_Dot := True;
         Pos := Pos + 1;
         -- .N means 0 to N
         Min_Count := 0;
         while Pos <= Pat'Length and then Is_Digit (Pat (Pos)) loop
            Max_Count := Max_Count * 10 +
              (Character'Pos (Pat (Pos)) - Character'Pos ('0'));
            Pos := Pos + 1;
         end loop;
         if Max_Count = 0 then
            Max_Count := Natural'Last; -- . means unlimited
         end if;
      elsif Pos <= Pat'Length and then Is_Digit (Pat (Pos)) then
         -- N or N.M
         while Pos <= Pat'Length and then Is_Digit (Pat (Pos)) loop
            Min_Count := Min_Count * 10 +
              (Character'Pos (Pat (Pos)) - Character'Pos ('0'));
            Pos := Pos + 1;
         end loop;
         if Pos <= Pat'Length and then Pat (Pos) = '.' then
            Has_Dot := True;
            Pos := Pos + 1;
            if Pos <= Pat'Length and then Is_Digit (Pat (Pos)) then
               -- N.M
               while Pos <= Pat'Length and then Is_Digit (Pat (Pos)) loop
                  Max_Count := Max_Count * 10 +
                    (Character'Pos (Pat (Pos)) - Character'Pos ('0'));
                  Pos := Pos + 1;
               end loop;
            else
               -- N. means N or more
               Max_Count := Natural'Last;
            end if;
         else
            -- Exact count N
            Max_Count := Min_Count;
         end if;
      else
         -- No count specified, default to 1
         Min_Count := 1;
         Max_Count := 1;
      end if;
   end Parse_Count;

   -- Match a string against a MUMPS pattern
   function Match (Str : String; Pat : String) return Boolean is
      Str_Pos : Natural := Str'First;
      Pat_Pos : Natural := Pat'First;
      Min_Count : Natural;
      Max_Count : Natural;
      Matched   : Natural;
   begin
      -- Process each pattern segment
      while Pat_Pos <= Pat'Length loop
         -- Parse count
         Parse_Count (Pat, Pat_Pos, Min_Count, Max_Count);

         -- Get pattern code
         if Pat_Pos > Pat'Length then
            return False; -- Incomplete pattern
         end if;

         declare
            Code : constant Character := Pat (Pat_Pos);
         begin
            Pat_Pos := Pat_Pos + 1;

            -- Match characters
            Matched := 0;
            while Str_Pos <= Str'Length and then
              (Max_Count = Natural'Last or else Matched < Max_Count) loop
               if Matches_Code (Str (Str_Pos), Code) then
                  Matched := Matched + 1;
                  Str_Pos := Str_Pos + 1;
               else
                  exit; -- Character doesn't match
               end if;
            end loop;

            -- Check if we matched enough
            if Matched < Min_Count then
               return False;
            end if;
         end;
      end loop;

      -- Must have consumed entire string
      return Str_Pos > Str'Length;
   end Match;

end Pattern;
