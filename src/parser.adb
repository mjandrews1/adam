-- Package: adam
-- File:    src/parser.adb
-- Summary: MUMPS Parser (AST Generation) implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Unchecked_Deallocation;

package body Parser is

   procedure Free is new Ada.Unchecked_Deallocation
     (AST_Node, AST_Node_Ptr);

   function Create_Node (Kind : Node_Kind;
                         Value : String := "";
                         Line : Natural := 0) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      Node := new AST_Node;
      Node.Kind := Kind;
      if Value'Length > 0 then
         Node.Value := To_Unbounded_String (Value);
      end if;
      Node.Line_Num := Line;
      return Node;
   end Create_Node;

   function Create_Parser (Source : String) return Parser_State is
      State : Parser_State;
   begin
      State.Lex := Create_Lexer (Source);
      State.Current := Next_Token (State.Lex);
      return State;
   end Create_Parser;

   procedure Advance (State : in out Parser_State) is
   begin
      State.Current := Next_Token (State.Lex);
   end Advance;

   procedure Expect (State : in out Parser_State;
                     Kind  : Token_Type) is
   begin
      if State.Current.Kind = Kind then
         Advance (State);
      end if;
   end Expect;

   -- Parse a variable (with optional subscripts)
   function Parse_Variable (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      Node := Create_Node (N_Variable, "", State.Current.Line);
      -- Get variable name - accept identifier or single-letter command tokens
      if State.Current.Kind = Tok_Identifier or else
        (State.Current.Kind >= Tok_BREAK and then
         State.Current.Kind <= Tok_XECUTE and then
         State.Current.Val_Len = 1) then
         Node.Value := To_Unbounded_String
           (State.Current.Value (1 .. State.Current.Val_Len));
         Advance (State);
      end if;
      -- Check for subscripts
      if State.Current.Kind = Tok_LParen then
         Advance (State);
         -- Parse subscript expressions
         while State.Current.Kind /= Tok_RParen and then
           State.Current.Kind /= Tok_EOF loop
            if State.Current.Kind = Tok_Comma then
               Advance (State);
            end if;
            -- Skip expression for now
            Advance (State);
         end loop;
         if State.Current.Kind = Tok_RParen then
            Advance (State);
         end if;
      end if;
      return Node;
   end Parse_Variable;

   -- Parse a primary expression (literal, variable, function)
   function Parse_Primary (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      case State.Current.Kind is
         when Tok_String =>
            Node := Create_Node (N_String_Lit,
                                State.Current.Value (1 .. State.Current.Val_Len),
                                State.Current.Line);
            Advance (State);
         when Tok_Number =>
            Node := Create_Node (N_Number_Lit,
                                State.Current.Value (1 .. State.Current.Val_Len),
                                State.Current.Line);
            Advance (State);
         when Tok_Identifier =>
            Node := Parse_Variable (State);
         when Tok_LParen =>
            Advance (State);
            Node := Parse_Expression (State);
            if State.Current.Kind = Tok_RParen then
               Advance (State);
            end if;
         when others =>
            Node := Create_Node (N_Null, "", State.Current.Line);
            Advance (State);
      end case;
      return Node;
   end Parse_Primary;

   -- Parse expression (simplified - just primary for now)
   function Parse_Expression (State : in out Parser_State) return AST_Node_Ptr is
   begin
      return Parse_Primary (State);
   end Parse_Expression;

   -- Parse SET command: S var=value
   function Parse_Set (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
      Var  : AST_Node_Ptr;
   begin
      Node := Create_Node (N_Set, "", State.Current.Line);
      Advance (State); -- Skip S/SET
      -- Parse variable
      Var := Parse_Variable (State);
      Node.Left := Var;
      -- Expect =
      if State.Current.Kind = Tok_Equals then
         Advance (State);
         -- Parse value expression
         Node.Right := Parse_Expression (State);
      end if;
      return Node;
   end Parse_Set;

   -- Parse WRITE command
   function Parse_Write (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      Node := Create_Node (N_Write, "", State.Current.Line);
      Advance (State); -- Skip W/WRITE
      -- Parse expression to write
      Node.Left := Parse_Expression (State);
      return Node;
   end Parse_Write;

   -- Parse a single command
   function Parse_Command (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      case State.Current.Kind is
         when Tok_SET =>
            Node := Parse_Set (State);
         when Tok_Write =>
            Node := Parse_Write (State);
         when Tok_Kill =>
            Node := Create_Node (N_Kill, "", State.Current.Line);
            Advance (State);
            Node.left := Parse_Variable (State);
         when Tok_Halt =>
            Node := Create_Node (N_Halt, "", State.Current.Line);
            Advance (State);
         when Tok_Quit =>
            Node := Create_Node (N_Quit, "", State.Current.Line);
            Advance (State);
         when Tok_Hang =>
            Node := Create_Node (N_Hang, "", State.Current.Line);
            Advance (State);
            Node.left := Parse_Expression (State);
         when Tok_Do =>
            Node := Create_Node (N_Do, "", State.Current.Line);
            Advance (State);
            -- Skip label reference for now
            if State.Current.Kind = Tok_Identifier then
               Advance (State);
            end if;
         when Tok_If =>
            Node := Create_Node (N_If, "", State.Current.Line);
            Advance (State);
            Node.left := Parse_Expression (State);
         when Tok_For =>
            Node := Create_Node (N_For, "", State.Current.Line);
            Advance (State);
            -- Skip for now
         when others =>
            Node := Create_Node (N_Null, "", State.Current.Line);
            Advance (State);
      end case;
      return Node;
   end Parse_Command;

   -- Parse a single line
   function Parse_Line (State : in out Parser_State) return AST_Node_Ptr is
      Line : AST_Node_Ptr;
      Cmd  : AST_Node_Ptr;
      Last : AST_Node_Ptr;
   begin
      -- Skip newlines
      while State.Current.Kind = Tok_Newline loop
         Advance (State);
      end loop;
      if State.Current.Kind = Tok_EOF then
         return null;
      end if;
      Line := Create_Node (N_Line, "", State.Current.Line);
      -- Check for tag
      if State.Current.Kind = Tok_Identifier then
         -- Could be a tag or command
         if State.Current.Val_Len > 0 and then
           State.Current.Value (1) >= 'A' and then
           State.Current.Value (1) <= 'Z' then
            -- Might be a command
            null;
         end if;
      end if;
      -- Parse commands on this line
      Cmd := Parse_Command (State);
      Line.Left := Cmd;
      Last := Cmd;
      -- Parse additional commands on same line (separated by space)
      while State.Current.Kind = Tok_Newline or else
        State.Current.Kind = Tok_Semicolon loop
         Advance (State);
         exit when State.Current.Kind = Tok_EOF;
         Cmd := Parse_Command (State);
         if Last /= null then
            Last.Next := Cmd;
         end if;
         Last := Cmd;
      end loop;
      return Line;
   end Parse_Line;

   -- Parse entire program
   function Parse_Program (State : in out Parser_State) return AST_Node_Ptr is
      Prog : AST_Node_Ptr;
      Line : AST_Node_Ptr;
      Last : AST_Node_Ptr;
   begin
      Prog := Create_Node (N_Program, "", 0);
      Line := Parse_Line (State);
      Prog.Left := Line;
      Last := Line;
      while Line /= null loop
         Line := Parse_Line (State);
         if Line /= null and then Last /= null then
            Last.Next := Line;
            Last := Line;
         end if;
      end loop;
      return Prog;
   end Parse_Program;

   procedure Destroy_AST (Node : in out AST_Node_Ptr) is
   begin
      if Node /= null then
         Destroy_AST (Node.Left);
         Destroy_AST (Node.Right);
         Destroy_AST (Node.Next);
         Free (Node);
      end if;
   end Destroy_AST;

end Parser;
