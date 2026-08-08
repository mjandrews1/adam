-- Package: adam
-- File:    src/mumps_types.ads
-- Summary: MUMPS type definitions
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Mumps_Types is

   -- MUMPS string type (unbounded for variable length)
   subtype Mumps_String is Unbounded_String;

   -- $DATA return codes
   -- 0 = undefined
   -- 1 = data only
   -- 10 = subscripts only
   -- 11 = both data and subscripts
   type Data_Code is range 0 .. 11;

   -- Pattern match result
   type Match_Result is (No_Match, Match_Found);

   -- Variable entry for symbol table
   type Var_Entry is record
      Name   : Mumps_String;
      Value  : Mumps_String;
      In_Use : Boolean := False;
   end record;

end Mumps_Types;
