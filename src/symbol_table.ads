-- Package: adam
-- File:    src/symbol_table.ads
-- Summary: MUMPS Symbol Table specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Symbol_Table is

   -- Set a local variable
   procedure Set_Var (Name : String; Value : String);

   -- Get a local variable (returns "" if undefined)
   function Get_Var (Name : String) return Unbounded_String;

   -- Check if a variable exists and has data
   function Var_Exists (Name : String) return Boolean;

   -- Kill a variable and all its subscripts
   procedure Kill_Var (Name : String);

   -- $DATA function
   -- Returns: 0=undefined, 1=data only, 10=subscripts only, 11=both
   function Var_Data (Name : String) return Natural;

   -- $ORDER function - get next subscript
   -- If Current is empty, returns first subscript
   -- If Current is non-empty, returns next subscript after Current
   function Var_Order (Name : String; Current : String := "")
     return Unbounded_String;

   -- Set a subscripted variable: NAME(sub1,sub2,...) = value
   procedure Set_Subscript (Name    : String;
                            Subs    : String;
                            Value   : String);

   -- Get a subscripted variable
   function Get_Subscript (Name : String; Subs : String)
     return Unbounded_String;

   -- MERGE - deep copy source subtree to destination
   procedure Merge_Var (Dest_Name : String;
                        Src_Name  : String);

   -- Kill all variables
   procedure Kill_All;

   -- List all variables (for debugging)
   procedure List_All;

end Symbol_Table;
