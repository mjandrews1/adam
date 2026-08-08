-- Package: adam
-- File:    src/database.adb
-- Summary: MUMPS Global Database implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Unbounded.Hash;
with Ada.Sequential_IO;
with Ada.Directories;

package body Database is

   -- Hash map for global storage
   package Global_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Unbounded_String,
      Element_Type    => Unbounded_String,
      Hash            => Ada.Strings.Unbounded.Hash,
      Equivalent_Keys => "=");

   Global_Map : Global_Maps.Map;

   -- Encode a global name with subscripts into a flat key
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

   procedure Set_Global (Name : String; Value : String) is
      Key : constant Unbounded_String := Encode_Key (Name);
   begin
      Global_Map.Include (Key, To_Unbounded_String (Value));
   end Set_Global;

   function Get_Global (Name : String) return Unbounded_String is
      Key : constant Unbounded_String := Encode_Key (Name);
   begin
      if Global_Map.Contains (Key) then
         return Global_Map.Element (Key);
      else
         return Null_Unbounded_String;
      end if;
   end Get_Global;

   function Global_Exists (Name : String) return Boolean is
      Key : constant Unbounded_String := Encode_Key (Name);
   begin
      return Global_Map.Contains (Key) and then
             Global_Map.Element (Key) /= Null_Unbounded_String;
   end Global_Exists;

   procedure Kill_Global (Name : String) is
      Key    : constant Unbounded_String := Encode_Key (Name);
      Prefix : constant String := Name & "(";
   begin
      if Global_Map.Contains (Key) then
         Global_Map.Delete (Key);
      end if;
      -- Kill all subscripts
      declare
         Keys_To_Delete : array (1 .. Natural (Global_Map.Length))
           of Unbounded_String;
         Count : Natural := 0;
      begin
         for C in Global_Map.Iterate loop
            if Starts_With (Global_Maps.Key (C), Prefix) then
               Count := Count + 1;
               Keys_To_Delete (Count) := Global_Maps.Key (C);
            end if;
         end loop;
         for I in 1 .. Count loop
            Global_Map.Delete (Keys_To_Delete (I));
         end loop;
      end;
   end Kill_Global;

   function Global_Data (Name : String) return Natural is
      Key      : constant Unbounded_String := Encode_Key (Name);
      Has_Data : Boolean := False;
      Has_Subs : Boolean := False;
      Prefix   : constant String := Name & "(";
   begin
      Has_Data := Global_Map.Contains (Key) and then
                  Global_Map.Element (Key) /= Null_Unbounded_String;
      for C in Global_Map.Iterate loop
         if Starts_With (Global_Maps.Key (C), Prefix) then
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
   end Global_Data;

   function Global_Order (Name : String; Current : String := "")
     return Unbounded_String is
      Prefix : constant String := Name & "(";
      Best   : Unbounded_String := Null_Unbounded_String;
   begin
      for C in Global_Map.Iterate loop
         declare
            Key : constant String := To_String (Global_Maps.Key (C));
         begin
            if Starts_With (Global_Maps.Key (C), Prefix) then
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
   end Global_Order;

   procedure Set_Global_Subscript (Name    : String;
                                   Subs    : String;
                                   Value   : String) is
      Key : constant Unbounded_String := Encode_Key (Name, Subs);
   begin
      Global_Map.Include (Key, To_Unbounded_String (Value));
   end Set_Global_Subscript;

   function Get_Global_Subscript (Name : String; Subs : String)
     return Unbounded_String is
      Key : constant Unbounded_String := Encode_Key (Name, Subs);
   begin
      if Global_Map.Contains (Key) then
         return Global_Map.Element (Key);
      else
         return Null_Unbounded_String;
      end if;
   end Get_Global_Subscript;

   function Global_Subscript_Exists (Name : String; Subs : String)
     return Boolean is
      Key : constant Unbounded_String := Encode_Key (Name, Subs);
   begin
      return Global_Map.Contains (Key) and then
             Global_Map.Element (Key) /= Null_Unbounded_String;
   end Global_Subscript_Exists;

   procedure Kill_Global_Subscript (Name : String; Subs : String) is
      Key    : constant Unbounded_String := Encode_Key (Name, Subs);
      Prefix : constant String := Name & "(" & Subs & "(";
   begin
      if Global_Map.Contains (Key) then
         Global_Map.Delete (Key);
      end if;
      declare
         Keys_To_Delete : array (1 .. Natural (Global_Map.Length))
           of Unbounded_String;
         Count : Natural := 0;
      begin
         for C in Global_Map.Iterate loop
            if Starts_With (Global_Maps.Key (C), Prefix) then
               Count := Count + 1;
               Keys_To_Delete (Count) := Global_Maps.Key (C);
            end if;
         end loop;
         for I in 1 .. Count loop
            Global_Map.Delete (Keys_To_Delete (I));
         end loop;
      end;
   end Kill_Global_Subscript;

   function Global_Subscript_Data (Name : String; Subs : String)
     return Natural is
      Key      : constant Unbounded_String := Encode_Key (Name, Subs);
      Has_Data : Boolean := False;
      Has_Subs : Boolean := False;
      Prefix   : constant String := Name & "(" & Subs & "(";
   begin
      Has_Data := Global_Map.Contains (Key) and then
                  Global_Map.Element (Key) /= Null_Unbounded_String;
      for C in Global_Map.Iterate loop
         if Starts_With (Global_Maps.Key (C), Prefix) then
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
   end Global_Subscript_Data;

   function Global_Subscript_Order (Name : String; Subs : String;
                                    Current : String := "")
     return Unbounded_String is
      Prefix : constant String := Name & "(" & Subs & "(";
      Best   : Unbounded_String := Null_Unbounded_String;
   begin
      for C in Global_Map.Iterate loop
         declare
            Key : constant String := To_String (Global_Maps.Key (C));
         begin
            if Starts_With (Global_Maps.Key (C), Prefix) then
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
   end Global_Subscript_Order;

   procedure Merge_Global (Dest_Name : String;
                           Src_Name  : String) is
      Src_Prefix  : constant String := Src_Name & "(";
      Dest_Prefix : constant String := Dest_Name & "(";
   begin
      declare
         Src_Key : constant Unbounded_String := Encode_Key (Src_Name);
      begin
         if Global_Map.Contains (Src_Key) then
            Global_Map.Include (Encode_Key (Dest_Name),
                               Global_Map.Element (Src_Key));
         end if;
      end;
      declare
         Keys_To_Copy : array (1 .. Natural (Global_Map.Length))
           of Unbounded_String;
         Count : Natural := 0;
      begin
         for C in Global_Map.Iterate loop
            if Starts_With (Global_Maps.Key (C), Src_Prefix) then
               Count := Count + 1;
               Keys_To_Copy (Count) := Global_Maps.Key (C);
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
               Global_Map.Include (New_Key,
                                  Global_Map.Element (Keys_To_Copy (I)));
            end;
         end loop;
      end;
   end Merge_Global;

   procedure Kill_All_Globals is
   begin
      Global_Map.Clear;
   end Kill_All_Globals;

   -- Persistence: Save database to file
   -- Format: text-based for portability
   -- Each line: key<TAB>value
   function Save (Filename : String) return Boolean is
      File : File_Type;
   begin
      Create (File, Out_File, Filename);
      for C in Global_Map.Iterate loop
         Put_Line (File, To_String (Global_Maps.Key (C)) & ASCII.HT &
                   To_String (Global_Maps.Element (C)));
      end loop;
      Close (File);
      return True;
   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;
         return False;
   end Save;

   -- Persistence: Load database from file
   function Load (Filename : String) return Boolean is
      File : File_Type;
      Line : Unbounded_String;
      Tab_Pos : Natural;
      Key_Str : Unbounded_String;
      Val_Str : Unbounded_String;
   begin
      if not Ada.Directories.Exists (Filename) then
         return False;
      end if;
      Open (File, In_File, Filename);
      while not End_Of_File (File) loop
         Line := To_Unbounded_String (Get_Line (File));
         Tab_Pos := 0;
         -- Find tab separator
         for I in 1 .. Length (Line) loop
            if Element (Line, I) = ASCII.HT then
               Tab_Pos := I;
               exit;
            end if;
         end loop;
         if Tab_Pos > 1 and then Tab_Pos < Length (Line) then
            Key_Str := Unbounded_Slice (Line, 1, Tab_Pos - 1);
            Val_Str := Unbounded_Slice (Line, Tab_Pos + 1, Length (Line));
            Global_Map.Include (Key_Str, Val_Str);
         end if;
      end loop;
      Close (File);
      return True;
   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;
         return False;
   end Load;

   procedure List_All_Globals is
   begin
      Put_Line ("Database Contents:");
      Put_Line ("==================");
      for C in Global_Map.Iterate loop
         Put_Line ("^" & To_String (Global_Maps.Key (C)) & " = " &
                   To_String (Global_Maps.Element (C)));
      end loop;
   end List_All_Globals;

end Database;
