-- Package: adam
-- File:    src/io.adb
-- Summary: MUMPS I/O Operations implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body IO is

   Max_Devices : constant Natural := 64;
   Buffer_Size : constant Natural := 4096;

   type Device_Buffer is record
      Input  : Unbounded_String;
      Output : Unbounded_String;
   end record;

   Devices : array (0 .. Max_Devices - 1) of Device_State;
   Buffers : array (0 .. Max_Devices - 1) of Device_Buffer;
   Current : Natural := 0;  -- Default to terminal (device 0)

   -- Initialize device array
   procedure Init_Devices is
   begin
      for I in Devices'Range loop
         Devices (I).Id := I;
         Devices (I).Name_Len := 0;
         Devices (I).Kind := Terminal;
         Devices (I).Is_Open := False;
         Devices (I).X := 0;
         Devices (I).Y := 0;
         Buffers (I).Input := Null_Unbounded_String;
         Buffers (I).Output := Null_Unbounded_String;
      end loop;
      -- Terminal (device 0) is always open
      Devices (0).Is_Open := True;
      Devices (0).Kind := Terminal;
   end Init_Devices;

   -- Initialize on package elaboration
   procedure Initialize is
   begin
      Init_Devices;
   end Initialize;

   -- Call initialize at elaboration time
   pragma Unreferenced (Initialize);

   procedure Open_Device (Id   : Natural;
                          Name : String;
                          Kind : Device_Type) is
   begin
      if Id < Max_Devices then
         Devices (Id).Id := Id;
         Devices (Id).Name (1 .. Name'Length) := Name;
         Devices (Id).Name_Len := Name'Length;
         Devices (Id).Kind := Kind;
         Devices (Id).Is_Open := True;
         Devices (Id).X := 0;
         Devices (Id).Y := 0;
         Buffers (Id).Input := Null_Unbounded_String;
         Buffers (Id).Output := Null_Unbounded_String;
      end if;
   end Open_Device;

   procedure Close_Device (Id : Natural) is
   begin
      if Id < Max_Devices and then Id /= 0 then
         Devices (Id).Is_Open := False;
      end if;
   end Close_Device;

   procedure Use_Device (Id : Natural) is
   begin
      if Id < Max_Devices and then Devices (Id).Is_Open then
         Current := Id;
      end if;
   end Use_Device;

   function Current_Device return Natural is
   begin
      return Current;
   end Current_Device;

   procedure Write (Data : String) is
   begin
      if Current < Max_Devices and then Devices (Current).Is_Open then
         if Current = 0 then
            -- Terminal output
            Put (Data);
         else
            -- Buffer output
            Append (Buffers (Current).Output, Data);
         end if;
         -- Update cursor position
         for I in Data'Range loop
            if Data (I) = ASCII.LF then
               Devices (Current).X := 0;
               Devices (Current).Y := Devices (Current).Y + 1;
            elsif Data (I) = ASCII.CR then
               Devices (Current).X := 0;
            else
               Devices (Current).X := Devices (Current).X + 1;
            end if;
         end loop;
      end if;
   end Write;

   procedure Write_Newline is
   begin
      Write ((1 => ASCII.LF));
   end Write_Newline;

   procedure Write_Form_Feed is
   begin
      Write ((1 => ASCII.FF));
   end Write_Form_Feed;

   procedure Write_Tab (Col : Natural) is
   begin
      if Current < Max_Devices and then Devices (Current).Is_Open then
         while Devices (Current).X < Col loop
            Write (" ");
         end loop;
      end if;
   end Write_Tab;

   procedure Write_Star (C : Character) is
   begin
      Write ((1 => C));
   end Write_Star;

   function Read return String is
   begin
      if Current < Max_Devices and then Devices (Current).Is_Open then
         if Current = 0 then
            -- Terminal input
            declare
               Line : String (1 .. 256);
               Last : Natural;
            begin
               Get_Line (Line, Last);
               return Line (1 .. Last);
            end;
         else
            -- Buffer input
            declare
               Result : constant String :=
                 To_String (Buffers (Current).Input);
            begin
               Buffers (Current).Input := Null_Unbounded_String;
               return Result;
            end;
         end if;
      end if;
      return "";
   end Read;

   function Read_Star return Character is
   begin
      if Current < Max_Devices and then Devices (Current).Is_Open then
         if Current = 0 then
            -- Terminal input
            declare
               C : Character;
            begin
               Get_Immediate (C);
               return C;
            end;
         else
            -- Buffer input
            declare
               Result : constant String :=
                 To_String (Buffers (Current).Input);
            begin
               if Result'Length > 0 then
                  Buffers (Current).Input :=
                    To_Unbounded_String (Result (Result'First + 1 .. Result'Last));
                  return Result (Result'First);
               end if;
            end;
         end if;
      end if;
      return ASCII.NUL;
   end Read_Star;

   function Get_X (Id : Natural) return Natural is
   begin
      if Id < Max_Devices then
         return Devices (Id).X;
      end if;
      return 0;
   end Get_X;

   function Get_Y (Id : Natural) return Natural is
   begin
      if Id < Max_Devices then
         return Devices (Id).Y;
      end if;
      return 0;
   end Get_Y;

   procedure Set_Position (Id : Natural; X : Natural; Y : Natural) is
   begin
      if Id < Max_Devices then
         Devices (Id).X := X;
         Devices (Id).Y := Y;
      end if;
   end Set_Position;

   function Is_Open (Id : Natural) return Boolean is
   begin
      if Id < Max_Devices then
         return Devices (Id).Is_Open;
      end if;
      return False;
   end Is_Open;

   function Get_Mode (Id : Natural) return Device_Type is
   begin
      if Id < Max_Devices then
         return Devices (Id).Kind;
      end if;
      return Terminal;
   end Get_Mode;

begin
   -- Initialize devices at package elaboration
   Init_Devices;
end IO;
