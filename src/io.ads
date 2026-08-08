-- Package: adam
-- File:    src/io.ads
-- Summary: MUMPS I/O Operations specification
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

package IO is

   -- Device types
   type Device_Type is (Terminal, File, Socket, Pipe);

   -- Device state
   type Device_State is record
      Id       : Natural;
      Name     : String (1 .. 256);
      Name_Len : Natural;
      Kind     : Device_Type;
      Is_Open  : Boolean;
      X        : Natural;  -- Cursor column
      Y        : Natural;  -- Cursor row
   end record;

   -- Open a device
   procedure Open_Device (Id   : Natural;
                          Name : String;
                          Kind : Device_Type);

   -- Close a device
   procedure Close_Device (Id : Natural);

   -- Use a device (set as current)
   procedure Use_Device (Id : Natural);

   -- Get current device ID
   function Current_Device return Natural;

   -- Write to current device
   procedure Write (Data : String);

   -- Write newline to current device
   procedure Write_Newline;

   -- Write form feed to current device
   procedure Write_Form_Feed;

   -- Write tab to column
   procedure Write_Tab (Col : Natural);

   -- Write single character
   procedure Write_Star (C : Character);

   -- Read from current device
   function Read return String;

   -- Read single character
   function Read_Star return Character;

   -- Get cursor X position
   function Get_X (Id : Natural) return Natural;

   -- Get cursor Y position
   function Get_Y (Id : Natural) return Natural;

   -- Set cursor position
   procedure Set_Position (Id : Natural; X : Natural; Y : Natural);

   -- Check if device is open
   function Is_Open (Id : Natural) return Boolean;

   -- Get device mode
   function Get_Mode (Id : Natural) return Device_Type;

end IO;
