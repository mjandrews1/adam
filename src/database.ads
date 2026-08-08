-- Package: adam
-- File:    src/database.ads
-- Summary: MUMPS Global Database specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Database is

   -- Set a global variable
   procedure Set_Global (Name : String; Value : String);

   -- Get a global variable (returns "" if undefined)
   function Get_Global (Name : String) return Unbounded_String;

   -- Check if a global exists and has data
   function Global_Exists (Name : String) return Boolean;

   -- Kill a global and all its subscripts
   procedure Kill_Global (Name : String);

   -- $DATA function
   -- Returns: 0=undefined, 1=data only, 10=subscripts only, 11=both
   function Global_Data (Name : String) return Natural;

   -- $ORDER function - get next subscript at depth 1
   function Global_Order (Name : String; Current : String := "")
     return Unbounded_String;

   -- Set a subscripted global: ^GLOBAL(sub1,sub2,...) = value
   procedure Set_Global_Subscript (Name    : String;
                                   Subs    : String;
                                   Value   : String);

   -- Get a subscripted global
   function Get_Global_Subscript (Name : String; Subs : String)
     return Unbounded_String;

   -- Check if subscripted global exists
   function Global_Subscript_Exists (Name : String; Subs : String)
     return Boolean;

   -- Kill a subscripted global
   procedure Kill_Global_Subscript (Name : String; Subs : String);

   -- $DATA for subscripted globals
   function Global_Subscript_Data (Name : String; Subs : String)
     return Natural;

   -- $ORDER for subscripted globals (deeper levels)
   function Global_Subscript_Order (Name : String; Subs : String;
                                    Current : String := "")
     return Unbounded_String;

   -- MERGE - deep copy source subtree to destination
   procedure Merge_Global (Dest_Name : String;
                           Src_Name  : String);

   -- Kill all globals
   procedure Kill_All_Globals;

   -- Persistence: Save database to file
   function Save (Filename : String) return Boolean;

   -- Persistence: Load database from file
   function Load (Filename : String) return Boolean;

   -- List all globals (for debugging)
   procedure List_All_Globals;

end Database;
