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

   -- Check if a key starts with a given prefix
   function Starts_With (Key : Unbounded_String;
                         Prefix : String) return Boolean is
      Key_Str : constant String := To_String (Key);
   begin
      if Key_Str'Length < Prefix'Length then
         return False;
      end if;
      return Key_Str (Key_Str'First .. Key_Str'First + Prefix'Length - 1)
        = Prefix;
   end Starts_With;

   procedure Set_Var (Name : String; Value : String) is
      Key : constant Unbounded_String := Encode_Key (Name);
   begin
      Var_Map.Include (Key, To_Unbounded_String (Value));
   end Set_Var;

   function Get_Var (Name : String) return Unbounded_String is
      Key : constant Unbounded_String := Encode_Key (Name);
   begin
      if Var_Map.Contains (Key) then
         return Var_Map.Element (Key);
      else
         return Null_Unbounded_String;
      end if;
   end Get_Var;

   function Var_Exists (Name : String) return Boolean is
      Key : constant Unbounded_String := Encode_Key (Name);
   begin
      return Var_Map.Contains (Key) and then
             Var_Map.Element (Key) /= Null_Unbounded_String;
   end Var_Exists;

   procedure Kill_Var (Name : String) is
      Key    : constant Unbounded_String := Encode_Key (Name);
      Prefix : constant String := Name & "(";
      Cursor : Var_Maps.Cursor;
      To_Delete : Unbounded_String;
   begin
      -- Kill the exact key
      if Var_Map.Contains (Key) then
         Var_Map.Delete (Key);
      end if;
      -- Kill all subscripts under this key
      -- Iterate and collect keys to delete (can't delete while iterating)
      declare
         type Key_Array is array (Positive range <>) of Unbounded_String;
         Keys_To_Delete : array (1 .. Natural (Var_Map.Length))
           of Unbounded_String;
         Count : Natural := 0;
      begin
         for C in Var_Map.Iterate loop
            if Starts_With (Var_Maps.Key (C), Prefix) then
               Count := Count + 1;
               Keys_To_Delete (Count) := Var_Maps.Key (C);
            end if;
         end loop;
         for I in 1 .. Count loop
            Var_Map.Delete (Keys_To_Delete (I));
         end loop;
      end;
   end Kill_Var;

   function Var_Data (Name : String) return Natural is
      Key      : constant Unbounded_String := Encode_Key (Name);
      Has_Data : Boolean := False;
      Has_Subs : Boolean := False;
      Prefix   : constant String := Name & "(";
   begin
      -- Check if the variable itself has data
      Has_Data := Var_Map.Contains (Key) and then
                  Var_Map.Element (Key) /= Null_Unbounded_String;
      -- Check if any subscripts exist
      for C in Var_Map.Iterate loop
         if Starts_With (Var_Maps.Key (C), Prefix) then
            Has_Subs := True;
            exit;
         end if;
      end loop;
      -- Return appropriate code
      if Has_Data and then Has_Subs then
         return 11;
      elsif Has_Data then
         return 1;
      elsif Has_Subs then
         return 10;
      else
         return 0;
      end if;
   end Var_Data;

   function Var_Order (Name : String; Current : String := "")
     return Unbounded_String is
      Prefix : constant String := Name & "(";
      Best   : Unbounded_String := Null_Unbounded_String;
      Best_Str : Unbounded_String := Null_Unbounded_String;
   begin
      -- Find all subscripts at depth 1
      for C in Var_Map.Iterate loop
         declare
            Key : constant String := To_String (Var_Maps.Key (C));
         begin
            if Starts_With (Var_Maps.Key (C), Prefix) then
               -- Extract the subscript (between first ( and first , or ))
               declare
                  Sub_Start : constant Natural := Key'First + Prefix'Length;
                  Sub_End   : Natural := Key'Last;
                  Comma_Pos : Natural := 0;
                  Close_Pos : Natural := 0;
               begin
                  -- Find comma or close paren at depth 1
                  for I in Sub_Start .. Key'Last loop
                     if Key (I) = ',' and then Comma_Pos = 0 then
                        Comma_Pos := I;
                     elsif Key (I) = ')' and then Close_Pos = 0 then
                        Close_Pos := I;
                     end if;
                  end loop;
                  if Comma_Pos > 0 then
                     Sub_End := Comma_Pos - 1;
                  elsif Close_Pos > 0 then
                     Sub_End := Close_Pos - 1;
                  end if;
                  if Sub_End >= Sub_Start then
                     declare
                        Sub : constant String :=
                          Key (Sub_Start .. Sub_End);
                     begin
                        if Current'Length = 0 then
                           -- Return first subscript
                           if Best = Null_Unbounded_String or else
                             Sub < To_String (Best) then
                              Best := To_Unbounded_String (Sub);
                           end if;
                        else
                           -- Return next subscript after Current
                           if Sub > Current then
                              if Best = Null_Unbounded_String or else
                                Sub < To_String (Best) then
                                 Best := To_Unbounded_String (Sub);
                              end if;
                           end if;
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;
      return Best;
   end Var_Order;

   procedure Set_Subscript (Name  : String;
                            Subs  : String;
                            Value : String) is
      Key : constant Unbounded_String := Encode_Key (Name, Subs);
   begin
      Var_Map.Include (Key, To_Unbounded_String (Value));
   end Set_Subscript;

   function Get_Subscript (Name : String; Subs : String)
     return Unbounded_String is
      Key : constant Unbounded_String := Encode_Key (Name, Subs);
   begin
      if Var_Map.Contains (Key) then
         return Var_Map.Element (Key);
      else
         return Null_Unbounded_String;
      end if;
   end Get_Subscript;

   function Subscript_Exists (Name : String; Subs : String)
     return Boolean is
      Key : constant Unbounded_String := Encode_Key (Name, Subs);
   begin
      return Var_Map.Contains (Key) and then
             Var_Map.Element (Key) /= Null_Unbounded_String;
   end Subscript_Exists;

   procedure Kill_Subscript (Name : String; Subs : String) is
      Key    : constant Unbounded_String := Encode_Key (Name, Subs);
      Prefix : constant String := Name & "(" & Subs & "(";
   begin
      -- Kill the exact subscript
      if Var_Map.Contains (Key) then
         Var_Map.Delete (Key);
      end if;
      -- Kill all deeper subscripts
      declare
         Keys_To_Delete : array (1 .. Natural (Var_Map.Length))
           of Unbounded_String;
         Count : Natural := 0;
      begin
         for C in Var_Map.Iterate loop
            if Starts_With (Var_Maps.Key (C), Prefix) then
               Count := Count + 1;
               Keys_To_Delete (Count) := Var_Maps.Key (C);
            end if;
         end loop;
         for I in 1 .. Count loop
            Var_Map.Delete (Keys_To_Delete (I));
         end loop;
      end;
   end Kill_Subscript;

   function Subscript_Data (Name : String; Subs : String) return Natural is
      Key      : constant Unbounded_String := Encode_Key (Name, Subs);
      Has_Data : Boolean := False;
      Has_Subs : Boolean := False;
      Prefix   : constant String := Name & "(" & Subs & "(";
   begin
      Has_Data := Var_Map.Contains (Key) and then
                  Var_Map.Element (Key) /= Null_Unbounded_String;
      for C in Var_Map.Iterate loop
         if Starts_With (Var_Maps.Key (C), Prefix) then
            Has_Subs := True;
            exit;
         end if;
      end loop;
      if Has_Data and then Has_Subs then
         return 11;
      elsif Has_Data then
         return 1;
      elsif Has_Subs then
         return 10;
      else
         return 0;
      end if;
   end Subscript_Data;

   function Subscript_Order (Name : String; Subs : String;
                             Current : String := "")
     return Unbounded_String is
      Prefix : constant String := Name & "(" & Subs & "(";
      Best   : Unbounded_String := Null_Unbounded_String;
   begin
      for C in Var_Map.Iterate loop
         declare
            Key : constant String := To_String (Var_Maps.Key (C));
         begin
            if Starts_With (Var_Maps.Key (C), Prefix) then
               -- Extract the subscript at the next level
               declare
                  Sub_Start : constant Natural := Key'First + Prefix'Length;
                  Sub_End   : Natural := Key'Last;
                  Comma_Pos : Natural := 0;
                  Close_Pos : Natural := 0;
               begin
                  for I in Sub_Start .. Key'Last loop
                     if Key (I) = ',' and then Comma_Pos = 0 then
                        Comma_Pos := I;
                     elsif Key (I) = ')' and then Close_Pos = 0 then
                        Close_Pos := I;
                     end if;
                  end loop;
                  if Comma_Pos > 0 then
                     Sub_End := Comma_Pos - 1;
                  elsif Close_Pos > 0 then
                     Sub_End := Close_Pos - 1;
                  end if;
                  if Sub_End >= Sub_Start then
                     declare
                        Sub : constant String :=
                          Key (Sub_Start .. Sub_End);
                     begin
                        if Current'Length = 0 then
                           if Best = Null_Unbounded_String or else
                             Sub < To_String (Best) then
                              Best := To_Unbounded_String (Sub);
                           end if;
                        else
                           if Sub > Current then
                              if Best = Null_Unbounded_String or else
                                Sub < To_String (Best) then
                                 Best := To_Unbounded_String (Sub);
                              end if;
                           end if;
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;
      return Best;
   end Subscript_Order;

   procedure Merge_Var (Dest_Name : String;
                        Src_Name  : String) is
      Src_Prefix  : constant String := Src_Name & "(";
      Dest_Prefix : constant String := Dest_Name & "(";
   begin
      -- Copy root value if it exists
      declare
         Src_Key : constant Unbounded_String := Encode_Key (Src_Name);
      begin
         if Var_Map.Contains (Src_Key) then
            Var_Map.Include (Encode_Key (Dest_Name),
                            Var_Map.Element (Src_Key));
         end if;
      end;
      -- Copy all subscripts (collect keys first, then insert)
      declare
         Keys_To_Copy : array (1 .. Natural (Var_Map.Length))
           of Unbounded_String;
         Count : Natural := 0;
      begin
         for C in Var_Map.Iterate loop
            if Starts_With (Var_Maps.Key (C), Src_Prefix) then
               Count := Count + 1;
               Keys_To_Copy (Count) := Var_Maps.Key (C);
            end if;
         end loop;
         for I in 1 .. Count loop
            declare
               Key : constant String := To_String (Keys_To_Copy (I));
               Suffix : constant String :=
                 Key (Key'First + Src_Prefix'Length .. Key'Last);
               New_Key : constant Unbounded_String :=
                 To_Unbounded_String (Dest_Prefix & Suffix);
            begin
               Var_Map.Include (New_Key, Var_Map.Element (Keys_To_Copy (I)));
            end;
         end loop;
      end;
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
