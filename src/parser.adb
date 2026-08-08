-- Package: adam
-- File:    src/parser.adb
-- Summary: MUMPS Parser (AST Generation) implementation
--
-- SPDX-FileCopyrightText:  2026 Mark J. Andrews
-- SPDX-License-Identifier: AGPL-3.0-or-later

with Ada.Unchecked_Deallocation;
with Ada.Characters.Handling; use Ada.Characters.Handling;

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

   -- Check if token is a comparison operator
   function Is_Comparison (Kind : Token_Type) return Boolean is
   begin
      return Kind = Tok_Equals or else Kind = Tok_NotEquals or else
             Kind = Tok_Less or else Kind = Tok_Greater or else
             Kind = Tok_LessEquals or else Kind = Tok_GreaterEquals or else
             Kind = Tok_Follows or else Kind = Tok_SortAfter or else
             Kind = Tok_Contains;
   end Is_Comparison;

   -- Map token type to AST node kind for binary operators
   function Token_To_Binary (Kind : Token_Type) return Node_Kind is
   begin
      case Kind is
         when Tok_Plus => return N_Add;
         when Tok_Minus => return N_Sub;
         when Tok_Star => return N_Mul;
         when Tok_Slash => return N_Div;
         when Tok_Backslash => return N_IntDiv;
         when Tok_Hash => return N_Mod;
         when Tok_StarStar => return N_Pow;
         when Tok_Concat => return N_Concat;
         when Tok_Equals => return N_Eql;
         when Tok_NotEquals => return N_Neql;
         when Tok_Less => return N_Lt;
         when Tok_Greater => return N_Gt;
         when Tok_LessEquals => return N_Lte;
         when Tok_GreaterEquals => return N_Gte;
         when Tok_Follows => return N_Follows;
         when Tok_SortAfter => return N_SortsAfter;
         when Tok_Contains => return N_Contains;
         when Tok_And => return N_And;
         when Tok_Or => return N_Or;
         when others => return N_Null;
      end case;
   end Token_To_Binary;

   -- Parse a primary expression (literal, variable, function, parenthesized)
   function Parse_Primary (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
      Func_Name : Unbounded_String;
      Args : AST_Node_Ptr;
      Last : AST_Node_Ptr;
      Arg : AST_Node_Ptr;
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
            -- Variable (possibly with subscripts)
            Node := Create_Node (N_Variable, "", State.Current.Line);
            Node.Value := To_Unbounded_String
              (State.Current.Value (1 .. State.Current.Val_Len));
            Advance (State);
            -- Check for subscripts
            if State.Current.Kind = Tok_LParen then
               Advance (State);
               while State.Current.Kind /= Tok_RParen and then
                 State.Current.Kind /= Tok_EOF loop
                  if State.Current.Kind = Tok_Comma then
                     Advance (State);
                  end if;
                  Arg := Parse_Expression (State);
                  if Node.Left = null then
                     Node.Left := Arg;
                  elsif Last /= null then
                     Last.Next := Arg;
                  end if;
                  Last := Arg;
               end loop;
               if State.Current.Kind = Tok_RParen then
                  Advance (State);
               end if;
            end if;

         when Tok_BREAK .. Tok_XECUTE =>
            -- Single-letter command tokens used as variable names (e.g., I, J, K, X)
            if State.Current.Val_Len = 1 then
               Node := Create_Node (N_Variable, "", State.Current.Line);
               Node.Value := To_Unbounded_String
                 (State.Current.Value (1 .. State.Current.Val_Len));
               Advance (State);
               -- Check for subscripts
               if State.Current.Kind = Tok_LParen then
                  Advance (State);
                  while State.Current.Kind /= Tok_RParen and then
                    State.Current.Kind /= Tok_EOF loop
                     if State.Current.Kind = Tok_Comma then
                        Advance (State);
                     end if;
                     Arg := Parse_Expression (State);
                     if Node.Left = null then
                        Node.Left := Arg;
                     elsif Last /= null then
                        Last.Next := Arg;
                     end if;
                     Last := Arg;
                  end loop;
                  if State.Current.Kind = Tok_RParen then
                     Advance (State);
                  end if;
               end if;
            else
               Node := Create_Node (N_Null, "", State.Current.Line);
               Advance (State);
            end if;

         when Tok_LParen =>
            -- Parenthesized expression
            Advance (State);
            Node := Parse_Expression (State);
            if State.Current.Kind = Tok_RParen then
               Advance (State);
            end if;

         when Tok_Minus =>
            -- Unary minus
            Advance (State);
            Node := Create_Node (N_UnaryMinus, "", State.Current.Line);
            Node.Left := Parse_Primary (State);

         when Tok_Plus =>
            -- Unary plus
            Advance (State);
            Node := Parse_Primary (State);

         when Tok_Not =>
            -- Logical NOT
            Advance (State);
            Node := Create_Node (N_Not, "", State.Current.Line);
            Node.left := Parse_Primary (State);

         when Tok_Dollar =>
            -- $ function call
            Advance (State);
            if State.Current.Kind = Tok_Identifier then
               Func_Name := To_Unbounded_String
                 (State.Current.Value (1 .. State.Current.Val_Len));
               Advance (State);
               Node := Create_Node (N_Function_Call, "", State.Current.Line);
               Node.Value := Func_Name;
               -- Parse arguments
               if State.Current.Kind = Tok_LParen then
                  Advance (State);
                  Args := null;
                  Last := null;
                  while State.Current.Kind /= Tok_RParen and then
                    State.Current.Kind /= Tok_EOF loop
                     if State.Current.Kind = Tok_Comma then
                        Advance (State);
                     end if;
                     Arg := Parse_Expression (State);
                     if Args = null then
                        Args := Arg;
                        Last := Arg;
                     elsif Last /= null then
                        Last.Next := Arg;
                        Last := Arg;
                     end if;
                  end loop;
                  Node.Left := Args;
                  if State.Current.Kind = Tok_RParen then
                     Advance (State);
                  end if;
               end if;
            else
               Node := Create_Node (N_Null, "", State.Current.Line);
            end if;

         when others =>
            Node := Create_Node (N_Null, "", State.Current.Line);
            Advance (State);
      end case;
      return Node;
   end Parse_Primary;

   -- Parse expression (MUMPS evaluates left-to-right, no precedence)
   function Parse_Expression (State : in out Parser_State) return AST_Node_Ptr is
      Left : AST_Node_Ptr;
      Node : AST_Node_Ptr;
      Op   : Node_Kind;
   begin
      Left := Parse_Primary (State);
      -- Parse binary operators left-to-right (no precedence)
      while Is_Comparison (State.Current.Kind) or else
        State.Current.Kind = Tok_Plus or else
        State.Current.Kind = Tok_Minus or else
        State.Current.Kind = Tok_Star or else
        State.Current.Kind = Tok_Slash or else
        State.Current.Kind = Tok_Backslash or else
        State.Current.Kind = Tok_Hash or else
        State.Current.Kind = Tok_Concat or else
        State.Current.Kind = Tok_And or else
        State.Current.Kind = Tok_Or loop
         Op := Token_To_Binary (State.Current.Kind);
         Advance (State);
         Node := Create_Node (Op, "", State.Current.Line);
         Node.left := Left;
         Node.right := Parse_Primary (State);
         Left := Node;
      end loop;
      return Left;
   end Parse_Expression;

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
         while State.Current.Kind /= Tok_RParen and then
           State.Current.Kind /= Tok_EOF loop
            if State.Current.Kind = Tok_Comma then
               Advance (State);
            end if;
            -- Parse subscript expression
            declare
               Arg : AST_Node_Ptr;
            begin
               Arg := Parse_Expression (State);
               if Node.Left = null then
                  Node.Left := Arg;
               end if;
            end;
         end loop;
         if State.Current.Kind = Tok_RParen then
            Advance (State);
         end if;
      end if;
      return Node;
   end Parse_Variable;

   -- Parse SET command: S var=expr
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
         Node.right := Parse_Expression (State);
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
      Node.left := Parse_Expression (State);
      return Node;
   end Parse_Write;

   -- Parse READ command
   function Parse_Read (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      Node := Create_Node (N_Read, "", State.Current.Line);
      Advance (State); -- Skip R/READ
      -- Parse variable to read into
      Node.left := Parse_Variable (State);
      return Node;
   end Parse_Read;

   -- Parse a single command
   function Parse_Command (State : in out Parser_State) return AST_Node_Ptr is
      Node : AST_Node_Ptr;
   begin
      case State.Current.Kind is
         when Tok_SET =>
            Node := Parse_Set (State);
         when Tok_Write =>
            Node := Parse_Write (State);
         when Tok_Read =>
            Node := Parse_Read (State);
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
            -- Optional quit value
            if State.Current.Kind /= Tok_Newline and then
              State.Current.Kind /= Tok_EOF and then
              State.Current.Kind /= Tok_Semicolon then
               Node.left := Parse_Expression (State);
            end if;
         when Tok_Hang =>
            Node := Create_Node (N_Hang, "", State.Current.Line);
            Advance (State);
            Node.left := Parse_Expression (State);
         when Tok_Do =>
            Node := Create_Node (N_Do, "", State.Current.Line);
            Advance (State);
            if State.Current.Kind = Tok_Identifier then
               Node.Value := To_Unbounded_String
                 (State.Current.Value (1 .. State.Current.Val_Len));
               Advance (State);
            end if;
         when Tok_If =>
            Node := Create_Node (N_If, "", State.Current.Line);
            Advance (State);
            Node.left := Parse_Expression (State);
         when Tok_For =>
            Node := Create_Node (N_For, "", State.Current.Line);
            Advance (State);
            -- Parse FOR var=start:increment:end
            -- Accept identifier or single-letter command token as variable name
            if State.Current.Kind = Tok_Identifier or else
              (State.Current.Kind >= Tok_BREAK and then
               State.Current.Kind <= Tok_XECUTE and then
               State.Current.Val_Len = 1) then
               -- Variable name
               Node.Value := To_Unbounded_String
                 (State.Current.Value (1 .. State.Current.Val_Len));
               Advance (State);
               -- Expect =
               if State.Current.Kind = Tok_Equals then
                  Advance (State);
                  -- Parse start expression
                  Node.left := Parse_Expression (State);
                  -- Expect :
                  if State.Current.Kind = Tok_Colon then
                     Advance (State);
                     -- Parse increment expression
                     Node.right := Parse_Expression (State);
                     -- Expect :
                     if State.Current.Kind = Tok_Colon then
                        Advance (State);
                        -- Parse end expression (store in left of Next)
                        Node.Next := Create_Node (N_Null, "", State.Current.Line);
                        Node.Next.left := Parse_Expression (State);
                     end if;
                  end if;
               end if;
            end if;
            -- Parse body command (rest of line)
            if State.Current.Kind /= Tok_Newline and then
              State.Current.Kind /= Tok_EOF then
               if Node.Next = null then
                  Node.Next := Create_Node (N_Null, "", State.Current.Line);
               end if;
               Node.Next.right := Parse_Command (State);
            end if;
         when Tok_Merge =>
            Node := Create_Node (N_Merge, "", State.Current.Line);
            Advance (State);
            -- Parse MERGE dest=source
            -- dest and source can be variables with subscripts
            if State.Current.Kind = Tok_Identifier or else
              (State.Current.Kind >= Tok_BREAK and then
               State.Current.Kind <= Tok_XECUTE and then
               State.Current.Val_Len = 1) then
               -- Destination variable
               Node.left := Parse_Variable (State);
               -- Expect =
               if State.Current.Kind = Tok_Equals then
                  Advance (State);
                  -- Source variable
                  Node.right := Parse_Variable (State);
               end if;
            end if;
         when Tok_New =>
            Node := Create_Node (N_New, "", State.Current.Line);
            Advance (State);
            -- Parse variable list: NEW var1,var2,...
            if State.Current.Kind = Tok_Identifier then
               Node.Value := To_Unbounded_String
                 (State.Current.Value (1 .. State.Current.Val_Len));
               Advance (State);
               -- Parse additional variables
               while State.Current.Kind = Tok_Comma loop
                  Advance (State);
                  if State.Current.Kind = Tok_Identifier then
                     Node.Value := Node.Value & "," &
                       To_Unbounded_String (State.Current.Value (1 .. State.Current.Val_Len));
                     Advance (State);
                  end if;
               end loop;
            end if;
         when Tok_Goto =>
            Node := Create_Node (N_Goto, "", State.Current.Line);
            Advance (State);
            if State.Current.Kind = Tok_Identifier then
               Node.Value := To_Unbounded_String
                 (State.Current.Value (1 .. State.Current.Val_Len));
               Advance (State);
            end if;
         when Tok_Else =>
            Node := Create_Node (N_Else, "", State.Current.Line);
            Advance (State);
         when Tok_Break =>
            Node := Create_Node (N_Break, "", State.Current.Line);
            Advance (State);
         when Tok_Job =>
            Node := Create_Node (N_Job, "", State.Current.Line);
            Advance (State);
         when Tok_Lock =>
            Node := Create_Node (N_Lock, "", State.Current.Line);
            Advance (State);
         when Tok_Xecute =>
            Node := Create_Node (N_Xecute, "", State.Current.Line);
            Advance (State);
            -- Parse string argument
            if State.Current.Kind = Tok_String then
               Node.left := Create_Node (N_String_Lit,
                 State.Current.Value (1 .. State.Current.Val_Len),
                 State.Current.Line);
               Advance (State);
            end if;
         when Tok_Use =>
            Node := Create_Node (N_Use, "", State.Current.Line);
            Advance (State);
         when Tok_Open =>
            Node := Create_Node (N_Open, "", State.Current.Line);
            Advance (State);
         when Tok_Close =>
            Node := Create_Node (N_Close, "", State.Current.Line);
            Advance (State);
         when Tok_View =>
            Node := Create_Node (N_View, "", State.Current.Line);
            Advance (State);
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
      -- Parse commands on this line
      Cmd := Parse_Command (State);
      Line.left := Cmd;
      Last := Cmd;
      -- Parse additional commands on same line
      -- MUMPS allows multiple commands on same line separated by spaces
      -- The lexer skips spaces, so we check if next token is a command
      while State.Current.Kind /= Tok_Newline and then
        State.Current.Kind /= Tok_EOF loop
         -- Check if next token is a command keyword
         exit when State.Current.Kind < Tok_BREAK;
         exit when State.Current.Kind > Tok_XECUTE;
         -- Skip if previous command was FOR (body already parsed)
         if Last /= null and then Last.Kind = N_For then
            exit;
         end if;
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
      Prog.left := Line;
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
         Destroy_AST (Node.left);
         Destroy_AST (Node.right);
         Destroy_AST (Node.Next);
         Free (Node);
      end if;
   end Destroy_AST;

end Parser;
