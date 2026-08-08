-- Package: adam
-- File:    src/string_funcs.ads
-- Summary: MUMPS String Functions specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Mumps_Types;           use Mumps_Types;

package String_Funcs is

   -- $ASCII - return ASCII code of character at position (1-based)
   -- Returns -1 if position is out of range
   function Dollar_ASCII (Str : String; Pos : Natural := 1) return Integer;

   -- $CHAR - return character from ASCII code
   function Dollar_CHAR (Code : Natural) return String;

   -- $LENGTH - return length of string
   function Dollar_LENGTH (Str : String) return Natural;

   -- $LENGTH - return number of pieces separated by delimiter
   function Dollar_LENGTH (Str : String; Delim : String) return Natural;

   -- $EXTRACT - extract substring by position (1-based)
   -- Returns empty string if out of range
   function Dollar_EXTRACT (Str : String;
                            Pos1 : Natural;
                            Pos2 : Natural := 0) return String;

   -- $FIND - find substring, return position after match (1-based)
   -- Returns 0 if not found
   function Dollar_FIND (Str : String;
                         Sub : String;
                         Start : Natural := 1) return Natural;

   -- $PIECE - extract delimited field (1-based)
   function Dollar_PIECE (Str : String;
                          Delim : String;
                          Piece1 : Natural;
                          Piece2 : Natural := 0) return String;

   -- $TRANSLATE - character substitution/deletion
   function Dollar_TRANSLATE (Str : String;
                              From : String;
                              To : String := "") return String;

   -- $REVERSE - reverse a string
   function Dollar_REVERSE (Str : String) return String;

   -- $JUSTIFY - right-justify in field
   function Dollar_JUSTIFY (Str : String;
                            Width : Natural) return String;

   -- $JUSTIFY - right-justify with decimal precision
   function Dollar_JUSTIFY (Num : String;
                            Width : Natural;
                            Decimals : Natural) return String;

   -- $SELECT - return first true condition's value
   function Dollar_SELECT (Conditions : Boolean_Array;
                           Values : String_Array) return String;

end String_Funcs;
