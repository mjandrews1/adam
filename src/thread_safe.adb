-- Package: adam
-- File:    src/thread_safe.adb
-- Summary: Thread-safe wrappers for shared data structures
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Symbol_Table;
with Database;

package body Thread_Safe is

   -- Thread-safe symbol table implementation
   protected body Protected_Symbol_Table is
      procedure Set_Var (Name : String; Value : String) is
      begin
         Symbol_Table.Set_Var (Name, Value);
      end Set_Var;

      function Get_Var (Name : String) return Unbounded_String is
      begin
         return Symbol_Table.Get_Var (Name);
      end Get_Var;

      function Var_Exists (Name : String) return Boolean is
      begin
         return Symbol_Table.Var_Exists (Name);
      end Var_Exists;

      procedure Kill_Var (Name : String) is
      begin
         Symbol_Table.Kill_Var (Name);
      end Kill_Var;

      function Var_Data (Name : String) return Natural is
      begin
         return Symbol_Table.Var_Data (Name);
      end Var_Data;

      procedure Set_Subscript (Name : String; Subs : String; Value : String) is
      begin
         Symbol_Table.Set_Subscript (Name, Subs, Value);
      end Set_Subscript;

      function Get_Subscript (Name : String; Subs : String) return Unbounded_String is
      begin
         return Symbol_Table.Get_Subscript (Name, Subs);
      end Get_Subscript;

      procedure Kill_Subscript (Name : String; Subs : String) is
      begin
         Symbol_Table.Kill_Subscript (Name, Subs);
      end Kill_Subscript;

      function Subscript_Exists (Name : String; Subs : String) return Boolean is
      begin
         return Symbol_Table.Subscript_Exists (Name, Subs);
      end Subscript_Exists;

      procedure Merge_Var (Dest_Name : String; Src_Name : String) is
      begin
         Symbol_Table.Merge_Var (Dest_Name, Src_Name);
      end Merge_Var;

      procedure Kill_All is
      begin
         Symbol_Table.Kill_All;
      end Kill_All;
   end Protected_Symbol_Table;

   -- Thread-safe database implementation
   protected body Protected_Database is
      procedure Set_Global (Name : String; Value : String) is
      begin
         Database.Set_Global (Name, Value);
      end Set_Global;

      function Get_Global (Name : String) return Unbounded_String is
      begin
         return Database.Get_Global (Name);
      end Get_Global;

      function Global_Exists (Name : String) return Boolean is
      begin
         return Database.Global_Exists (Name);
      end Global_Exists;

      procedure Kill_Global (Name : String) is
      begin
         Database.Kill_Global (Name);
      end Kill_Global;

      function Global_Data (Name : String) return Natural is
      begin
         return Database.Global_Data (Name);
      end Global_Data;

      procedure Set_Global_Subscript (Name : String; Subs : String; Value : String) is
      begin
         Database.Set_Global_Subscript (Name, Subs, Value);
      end Set_Global_Subscript;

      function Get_Global_Subscript (Name : String; Subs : String) return Unbounded_String is
      begin
         return Database.Get_Global_Subscript (Name, Subs);
      end Get_Global_Subscript;

      procedure Kill_Global_Subscript (Name : String; Subs : String) is
      begin
         Database.Kill_Global_Subscript (Name, Subs);
      end Kill_Global_Subscript;

      procedure Merge_Global (Dest_Name : String; Src_Name : String) is
      begin
         Database.Merge_Global (Dest_Name, Src_Name);
      end Merge_Global;

      procedure Kill_All_Globals is
      begin
         Database.Kill_All_Globals;
      end Kill_All_Globals;
   end Protected_Database;

   -- Lock table implementation
   protected body Lock_Table is
      entry Acquire (Name : String; Timeout : Duration) when Lock_Count < 100 is
      begin
         Lock_Count := Lock_Count + 1;
      end Acquire;

      procedure Release (Name : String) is
      begin
         if Lock_Count > 0 then
            Lock_Count := Lock_Count - 1;
         end if;
      end Release;

      function Is_Locked (Name : String) return Boolean is
      begin
         return Lock_Count > 0;
      end Is_Locked;

      procedure Release_All is
      begin
         Lock_Count := 0;
      end Release_All;
   end Lock_Table;

end Thread_Safe;
