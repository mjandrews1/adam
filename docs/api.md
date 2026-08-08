# adam API Documentation

## Overview

adam is a MUMPS (M) implementation written in Ada. It provides a complete MUMPS runtime environment including:

- Symbol table with subscripted variable support
- Global database with persistence
- Pattern matching with MUMPS syntax
- I/O operations with device management
- String functions ($EXTRACT, $LENGTH, $PIECE, etc.)
- Lexer, parser, and runtime interpreter

## Modules

### Symbol Table (`symbol_table.ads/adb`)

Local variable storage with subscript support.

#### Operations

| Function | Description |
|----------|-------------|
| `Set_Var(Name, Value)` | Set a local variable |
| `Get_Var(Name) return String` | Get a local variable |
| `Var_Exists(Name) return Boolean` | Check if variable exists |
| `Kill_Var(Name)` | Kill variable and all subscripts |
| `Var_Data(Name) return Natural` | $DATA function (0/1/10/11) |
| `Var_Order(Name, Current) return String` | $ORDER function |
| `Set_Subscript(Name, Subs, Value)` | Set subscripted variable |
| `Get_Subscript(Name, Subs) return String` | Get subscripted variable |
| `Subscript_Exists(Name, Subs) return Boolean` | Check if subscript exists |
| `Kill_Subscript(Name, Subs)` | Kill subscripted variable |
| `Subscript_Data(Name, Subs) return Natural` | $DATA for subscripts |
| `Subscript_Order(Name, Subs, Current) return String` | $ORDER for subscripts |
| `Merge_Var(Dest_Name, Src_Name)` | MERGE - deep copy subtree |
| `Kill_All` | Kill all variables |
| `List_All` | List all variables (debug) |

#### $DATA Return Codes

| Code | Meaning |
|------|---------|
| 0 | Undefined |
| 1 | Data only |
| 10 | Subscripts only |
| 11 | Both data and subscripts |

### Database (`database.ads/adb`)

Global variable storage with persistence.

#### Operations

| Function | Description |
|----------|-------------|
| `Set_Global(Name, Value)` | Set a global variable |
| `Get_Global(Name) return String` | Get a global variable |
| `Global_Exists(Name) return Boolean` | Check if global exists |
| `Kill_Global(Name)` | Kill global and all subscripts |
| `Global_Data(Name) return Natural` | $DATA function |
| `Global_Order(Name, Current) return String` | $ORDER function |
| `Set_Global_Subscript(Name, Subs, Value)` | Set subscripted global |
| `Get_Global_Subscript(Name, Subs) return String` | Get subscripted global |
| `Global_Subscript_Exists(Name, Subs) return Boolean` | Check if subscript exists |
| `Kill_Global_Subscript(Name, Subs)` | Kill subscripted global |
| `Merge_Global(Dest_Name, Src_Name)` | MERGE - deep copy subtree |
| `Kill_All_Globals` | Kill all globals |
| `Save(Filename) return Boolean` | Save database to file |
| `Load(Filename) return Boolean` | Load database from file |
| `List_All_Globals` | List all globals (debug) |

### Pattern Matching (`pattern.ads/adb`)

MUMPS pattern matching syntax.

#### Pattern Codes

| Code | Description |
|------|-------------|
| `A` | Letters (A-Z, a-z) |
| `N` | Digits (0-9) |
| `E` | Everything (any character) |
| `U` | Uppercase letters |
| `L` | Lowercase letters |
| `P` | Punctuation |
| `C` | Control characters |

#### Count Specifications

| Format | Description |
|--------|-------------|
| `3A` | Exactly 3 letters |
| `2.5A` | 2 to 5 letters |
| `.3A` | 0 to 3 letters |
| `3.A` | 3 or more letters |

#### Function

```ada
function Match(Str : String; Pat : String) return Boolean;
```

### I/O (`io.ads/adb`)

Device management and I/O operations.

#### Device Types

| Type | Description |
|------|-------------|
| `Terminal` | Standard terminal I/O |
| `File` | File I/O |
| `Socket` | Socket I/O |
| `Pipe` | Pipe I/O |

#### Operations

| Function | Description |
|----------|-------------|
| `Open_Device(Id, Name, Kind)` | Open a device |
| `Close_Device(Id)` | Close a device |
| `Use_Device(Id)` | Set current device |
| `Current_Device return Natural` | Get current device ID |
| `Write(Data)` | Write to current device |
| `Write_Newline` | Write newline |
| `Write_Form_Feed` | Write form feed |
| `Write_Tab(Col)` | Write tab to column |
| `Write_Star(C)` | Write single character |
| `Read return String` | Read from current device |
| `Read_Star return Character` | Read single character |
| `Get_X(Id) return Natural` | Get cursor X position |
| `Get_Y(Id) return Natural` | Get cursor Y position |
| `Set_Position(Id, X, Y)` | Set cursor position |
| `Is_Open(Id) return Boolean` | Check if device is open |
| `Get_Mode(Id) return Device_Type` | Get device mode |

### String Functions (`string_funcs.ads/adb`)

MUMPS string intrinsic functions.

| Function | Description |
|----------|-------------|
| `$ASCII(Str, Pos)` | ASCII code at position (1-based) |
| `$CHAR(Code)` | Character from ASCII code |
| `$LENGTH(Str)` | String length |
| `$LENGTH(Str, Delim)` | Number of pieces |
| `$EXTRACT(Str, Pos1, Pos2)` | Extract substring |
| `$FIND(Str, Sub, Start)` | Find substring position |
| `$PIECE(Str, Delim, Piece1, Piece2)` | Extract delimited field |
| `$TRANSLATE(Str, From, To)` | Character substitution |
| `$REVERSE(Str)` | Reverse string |
| `$JUSTIFY(Str, Width)` | Right-justify |
| `$JUSTIFY(Num, Width, Decimals)` | Right-justify with decimals |
| `$SELECT(Conditions, Values)` | Conditional value selection |

### Lexer (`lexer.ads/adb`)

Tokenizer for MUMPS source code.

#### Token Types

- Literals: `Tok_String`, `Tok_Number`, `Tok_Identifier`
- Commands: `Tok_BREAK` through `Tok_XECUTE` (all 22 commands)
- Operators: `Tok_Plus`, `Tok_Minus`, `Tok_Star`, `Tok_Slash`, etc.
- Delimiters: `Tok_LParen`, `Tok_RParen`, `Tok_Comma`, `Tok_Colon`, `Tok_Semicolon`

#### Functions

| Function | Description |
|----------|-------------|
| `Create_Lexer(Source) return Lexer_State` | Initialize lexer |
| `Next_Token(State) return Token` | Get next token |
| `Peek_Token(State) return Token` | Peek at current token |
| `Has_More(State) return Boolean` | Check if more tokens |

### Parser (`parser.ads/adb`)

AST generation for MUMPS programs.

#### Node Types

- Program structure: `N_Program`, `N_Line`, `N_Tag`
- Commands: `N_Set`, `N_Write`, `N_Read`, `N_Kill`, etc.
- Expressions: `N_String_Lit`, `N_Number_Lit`, `N_Variable`, etc.

#### Functions

| Function | Description |
|----------|-------------|
| `Create_Parser(Source) return Parser_State` | Initialize parser |
| `Parse_Program(State) return AST_Node_Ptr` | Parse program |
| `Parse_Line(State) return AST_Node_Ptr` | Parse single line |
| `Parse_Expression(State) return AST_Node_Ptr` | Parse expression |
| `Destroy_AST(Node)` | Destroy AST |

### Runtime (`runtime.ads/adb`)

Execution engine for MUMPS programs.

#### Functions

| Function | Description |
|----------|-------------|
| `Create_Runtime return Runtime_State` | Initialize runtime |
| `Execute(State, Prog)` | Execute program |
| `Execute_Line(State, Line)` | Execute single line |
| `Get_Test_Result(State) return Boolean` | Get $TEST result |
| `Get_Error_Code(State) return Integer` | Get error code |
| `Get_Error_Message(State) return String` | Get error message |
| `Is_Halted(State) return Boolean` | Check if halted |

## Supported Commands

| Command | Abbreviation | Status |
|---------|--------------|--------|
| BREAK | B | Parsed |
| CLOSE | C | Parsed |
| DO | D | Parsed |
| ELSE | E | Parsed |
| FOR | F | Parsed |
| GOTO | G | Parsed |
| HALT | H | Implemented |
| HANG | H | Parsed |
| IF | I | Implemented |
| JOB | J | Parsed |
| KILL | K | Implemented |
| LOCK | L | Parsed |
| MERGE | M | Parsed |
| NEW | N | Parsed |
| OPEN | O | Parsed |
| QUIT | Q | Implemented |
| READ | R | Parsed |
| SET | S | Implemented |
| USE | U | Parsed |
| VIEW | V | Parsed |
| WRITE | W | Implemented |
| XECUTE | X | Parsed |

## Building

```bash
# Set up environment
source setup_env.sh

# Build
gprbuild -P adam.gpr

# Run
./bin/main

# Run tests
./bin/main 2>&1 | grep -E "^(Total|Passed|Failed)"
```

## Examples

See `examples/` directory for sample MUMPS programs:
- `hello.mumps` - Hello World
- `factorial.mumps` - Factorial calculation
- `fibonacci.mumps` - Fibonacci sequence
