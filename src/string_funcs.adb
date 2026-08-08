-- Package: adam
-- File:    src/string_funcs.adb
-- Summary: MUMPS String Functions implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with Ada.Strings.Maps;      use Ada.Strings.Maps;
with Mumps_Types;           use Mumps_Types;

package body String_Funcs is

   -- $ASCII - return ASCII code of character at position (1-based)
   function Dollar_ASCII (Str : String; Pos : Natural := 1) return Integer is
   begin
      if Pos >= 1 and then Pos <= Str'Length then
         return Character'Pos (Str (Str'First + Pos - 1));
      end if;
      return -1;
   end Dollar_ASCII;

   -- $CHAR - return character from ASCII code
   function Dollar_CHAR (Code : Natural) return String is
   begin
      if Code <= 255 then
         return (1 => Character'Val (Code));
      end if;
      return "";
   end Dollar_CHAR;

   -- $LENGTH - return length of string
   function Dollar_LENGTH (Str : String) return Natural is
   begin
      return Str'Length;
   end Dollar_LENGTH;

   -- $LENGTH - return number of pieces separated by delimiter
   function Dollar_LENGTH (Str : String; Delim : String) return Natural is
      Count  : Natural := 1;
      Pos    : Natural;
      Start  : Natural := Str'First;
   begin
      if Delim'Length = 0 then
         return Str'Length;
      end if;
      if Str'Length = 0 then
         return 0;
      end if;
      loop
         Pos := Index (Str (Start .. Str'Last), Delim);
         exit when Pos = 0;
         Count := Count + 1;
         Start := Pos + Delim'Length;
      end loop;
      return Count;
   end Dollar_LENGTH;

   -- $EXTRACT - extract substring by position (1-based)
   function Dollar_EXTRACT (Str : String;
                            Pos1 : Natural;
                            Pos2 : Natural := 0) return String is
      Actual_Pos2 : Natural;
      Start       : Natural;
      Finish      : Natural;
   begin
      if Pos2 = 0 then
         Actual_Pos2 := Pos1;
      else
         Actual_Pos2 := Pos2;
      end if;
      Start := Str'First + Pos1 - 1;
      Finish := Str'First + Actual_Pos2 - 1;
      if Start > Str'Last or else Finish < Str'First then
         return "";
      end if;
      if Start < Str'First then
         Start := Str'First;
      end if;
      if Finish > Str'Last then
         Finish := Str'Last;
      end if;
      return Str (Start .. Finish);
   end Dollar_EXTRACT;

   -- $FIND - find substring, return position after match (1-based)
   function Dollar_FIND (Str : String;
                         Sub : String;
                         Start : Natural := 1) return Natural is
      Pos : Natural;
   begin
      if Start > Str'Length + 1 then
         return 0;
      end if;
      Pos := Index (Str (Str'First + Start - 1 .. Str'Last), Sub);
      if Pos > 0 then
         return Pos - Str'First + 1 + Sub'Length;
      end if;
      return 0;
   end Dollar_FIND;

   -- $PIECE - extract delimited field (1-based)
   function Dollar_PIECE (Str : String;
                          Delim : String;
                          Piece1 : Natural;
                          Piece2 : Natural := 0) return String is
      Actual_Piece2 : Natural;
      Count         : Natural := 1;
      Pos           : Natural;
      Start         : Natural := Str'First;
      Piece_Start   : Natural := 0;
      Piece_End     : Natural := 0;
   begin
      if Piece2 = 0 then
         Actual_Piece2 := Piece1;
      else
         Actual_Piece2 := Piece2;
      end if;
      if Delim'Length = 0 then
         return Str;
      end if;
      loop
         Pos := Index (Str (Start .. Str'Last), Delim);
         if Count = Piece1 then
            Piece_Start := Start;
         end if;
         if Pos = 0 then
            if Count >= Piece1 and then Count <= Actual_Piece2 then
               Piece_End := Str'Last;
            end if;
            exit;
         end if;
         if Count = Actual_Piece2 then
            Piece_End := Pos - 1;
            exit;
         end if;
         Count := Count + 1;
         Start := Pos + Delim'Length;
      end loop;
      if Piece_Start > 0 and then Piece_End > 0 then
         return Str (Piece_Start .. Piece_End);
      end if;
      return "";
   end Dollar_PIECE;

   -- $TRANSLATE - character substitution/deletion
   function Dollar_TRANSLATE (Str : String;
                              From : String;
                              To : String := "") return String is
      Result : Unbounded_String;
      Found  : Boolean;
   begin
      for I in Str'Range loop
         Found := False;
         for J in From'Range loop
            if Str (I) = From (J) then
               if J - From'First + 1 <= To'Length then
                  Append (Result, To (To'First + J - From'First));
               end if;
               -- If no corresponding To character, character is deleted
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            Append (Result, Str (I));
         end if;
      end loop;
      return To_String (Result);
   end Dollar_TRANSLATE;

   -- $REVERSE - reverse a string
   function Dollar_REVERSE (Str : String) return String is
      Result : String (Str'Range);
   begin
      for I in Str'Range loop
         Result (Str'First + Str'Last - I) := Str (I);
      end loop;
      return Result;
   end Dollar_REVERSE;

   -- $JUSTIFY - right-justify in field
   function Dollar_JUSTIFY (Str : String;
                            Width : Natural) return String is
   begin
      if Str'Length >= Width then
         return Str;
      end if;
      return (Width - Str'Length) * ' ' & Str;
   end Dollar_JUSTIFY;

   -- $JUSTIFY - right-justify with decimal precision
   function Dollar_JUSTIFY (Num : String;
                            Width : Natural;
                            Decimals : Natural) return String is
      Dot_Pos  : Natural;
      Int_Part : Unbounded_String;
      Frac_Part : Unbounded_String;
      Result   : Unbounded_String;
   begin
      Dot_Pos := Index (Num, ".");
      if Dot_Pos = 0 then
         Int_Part := To_Unbounded_String (Num);
         Frac_Part := Null_Unbounded_String;
      else
         Int_Part := To_Unbounded_String (Num (Num'First .. Dot_Pos - 1));
         Frac_Part := To_Unbounded_String (Num (Dot_Pos + 1 .. Num'Last));
      end if;
      -- Pad or truncate fractional part
      if Length (Frac_Part) < Decimals then
         for I in 1 .. Decimals - Length (Frac_Part) loop
            Append (Frac_Part, '0');
         end loop;
      elsif Length (Frac_Part) > Decimals then
         Frac_Part := Unbounded_Slice (Frac_Part, 1, Decimals);
      end if;
      if Decimals > 0 then
         Result := Int_Part & "." & Frac_Part;
      else
         Result := Int_Part;
      end if;
      -- Right-justify in field
      if Length (Result) < Width then
         declare
            Padding : constant String (1 .. Width - Length (Result)) :=
              (others => ' ');
         begin
            Result := To_Unbounded_String (Padding) & Result;
         end;
      end if;
      return To_String (Result);
   end Dollar_JUSTIFY;

   -- $SELECT - return first true condition's value
   function Dollar_SELECT (Conditions : Boolean_Array;
                           Values : String_Array) return String is
   begin
      for I in Conditions'Range loop
         if Conditions (I) then
            if I - Conditions'First + 1 <= Values'Length then
               return To_String (Values (Values'First + I - Conditions'First));
            end if;
         end if;
      end loop;
      return "";
   end Dollar_SELECT;

end String_Funcs;
