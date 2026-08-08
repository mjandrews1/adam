-- Package: adam
-- File:    src/symbol_table.adb
-- Summary: MUMPS Symbol Table implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Unbounded.Hash;

package body Symbol_Table is

   -- Hash map for variable storage
   -- Keys are encoded as "NAME" or "NAME(sub1,sub2,...)"
   package Var_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Unbounded_String,
      Element_Type    => Unbounded_String,
      Hash            => Ada.Strings.Unbounded.Hash,
      Equivalent_Keys => "=");

   Var_Map : Var_Maps.Map;

   -- Encode a variable name with subscripts into a flat key
   function Encode_Key (Name : String; Subs : String := "")
     return Unbounded_String is
   begin
      if Subs'Length = 0 then
         return To_Unbounded_String (Name);
      else
         return To_Unbounded_String (Name & "(" & Subs & ")");
      end if;
   end Encode_Key;

   procedure Set_Var (Name : String; Value : String) is
      Key : Unbounded_String := Encode_Key (Name);
   begin
      Var_Map.Include (Key, To_Unbounded_String (Value));
   end Set_Var;

   function Get_Var (Name : String) return Unbounded_String is
      Key : Unbounded_String := Encode_Key (Name);
   begin
      if Var_Map.Contains (Key) then
         return Var_Map.Element (Key);
      else
         return Null_Unbounded_String;
      end if;
   end Get_Var;

   function Var_Exists (Name : String) return Boolean is
      Key : Unbounded_String := Encode_Key (Name);
   begin
      return Var_Map.Contains (Key) and then
             Var_Map.Element (Key) /= Null_Unbounded_String;
   end Var_Exists;

   procedure Kill_Var (Name : String) is
      Key    : Unbounded_String := Encode_Key (Name);
      Prefix : Unbounded_String := To_Unbounded_String (Name & "(");
   begin
      -- Kill the exact key
      if Var_Map.Contains (Key) then
         Var_Map.Delete (Key);
      end if;
      -- Kill all subscripts under this key
      -- (In a full implementation, iterate and delete matching keys)
   end Kill_Var;

   function Var_Data (Name : String) return Natural is
      Key      : Unbounded_String := Encode_Key (Name);
      Has_Data : Boolean := False;
      Has_Subs : Boolean := False;
   begin
      Has_Data := Var_Map.Contains (Key) and then
                  Var_Map.Element (Key) /= Null_Unbounded_String;
      -- Check for subscripts (simplified)
      -- In full implementation, iterate map for prefix matches
      if Has_Data then
         return 1;
      else
         return 0;
      end if;
   end Var_Data;

   function Var_Order (Name : String; Current : String := "")
     return Unbounded_String is
   begin
      -- Simplified implementation
      return Null_Unbounded_String;
   end Var_Order;

   procedure Set_Subscript (Name  : String;
                            Subs  : String;
                            Value : String) is
      Key : Unbounded_String := Encode_Key (Name, Subs);
   begin
      Var_Map.Include (Key, To_Unbounded_String (Value));
   end Set_Subscript;

   function Get_Subscript (Name : String; Subs : String)
     return Unbounded_String is
      Key : Unbounded_String := Encode_Key (Name, Subs);
   begin
      if Var_Map.Contains (Key) then
         return Var_Map.Element (Key);
      else
         return Null_Unbounded_String;
      end if;
   end Get_Subscript;

   procedure Merge_Var (Dest_Name : String;
                        Src_Name  : String) is
   begin
      -- Simplified implementation
      null;
   end Merge_Var;

   procedure Kill_All is
   begin
      Var_Map.Clear;
   end Kill_All;

   procedure List_All is
   begin
      Put_Line ("Symbol Table Contents:");
      Put_Line ("=====================");
      for C in Var_Map.Iterate loop
         Put_Line (To_String (Var_Maps.Key (C)) & " = " &
                   To_String (Var_Maps.Element (C)));
      end loop;
   end List_All;

end Symbol_Table;
