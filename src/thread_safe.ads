-- Package: adam
-- File:    src/thread_safe.ads
-- Summary: Thread-safe wrappers for shared data structures
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Thread_Safe is

   -- Thread-safe symbol table
   protected type Protected_Symbol_Table is
      procedure Set_Var (Name : String; Value : String);
      function Get_Var (Name : String) return Unbounded_String;
      function Var_Exists (Name : String) return Boolean;
      procedure Kill_Var (Name : String);
      function Var_Data (Name : String) return Natural;
      procedure Set_Subscript (Name : String; Subs : String; Value : String);
      function Get_Subscript (Name : String; Subs : String) return Unbounded_String;
      procedure Kill_Subscript (Name : String; Subs : String);
      function Subscript_Exists (Name : String; Subs : String) return Boolean;
      procedure Merge_Var (Dest_Name : String; Src_Name : String);
      procedure Kill_All;
   end Protected_Symbol_Table;

   -- Thread-safe global database
   protected type Protected_Database is
      procedure Set_Global (Name : String; Value : String);
      function Get_Global (Name : String) return Unbounded_String;
      function Global_Exists (Name : String) return Boolean;
      procedure Kill_Global (Name : String);
      function Global_Data (Name : String) return Natural;
      procedure Set_Global_Subscript (Name : String; Subs : String; Value : String);
      function Get_Global_Subscript (Name : String; Subs : String) return Unbounded_String;
      procedure Kill_Global_Subscript (Name : String; Subs : String);
      procedure Merge_Global (Dest_Name : String; Src_Name : String);
      procedure Kill_All_Globals;
   end Protected_Database;

   -- Lock table for MUMPS LOCK command
   protected type Lock_Table is
      entry Acquire (Name : String; Timeout : Duration);
      procedure Release (Name : String);
      function Is_Locked (Name : String) return Boolean;
      procedure Release_All;
   private
      Lock_Count : Natural := 0;
   end Lock_Table;

end Thread_Safe;
