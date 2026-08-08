# adam — M/MUMPS in Ada

A port of [RFC](https://github.com/mjandrews1/rfc) (a fork of [RSM](https://gitlab.com/Reference-Standard-M/rsm)) to the Ada programming language.

## Origin

- **RSM** — Reference Standard M by David Wicksell (Fourth Watch Software LC), derived from MUMPS V1 by Raymond Douglas Newman
- **RFC** — ReFaCtored Standard M, a fork of RSM by Mark J. Andrews
- **adam** — RFC ported to Ada

## License

AGPL-3.0-or-later (same as RSM and RFC)

## Prerequisites

GNAT (Ada compiler) and gprbuild must be installed via Alire:

```bash
# Install Alire
curl -sL https://github.com/alire-project/alire/releases/latest/download/alr-2.1.1-bin-x86_64-macos.zip -o /tmp/alr.zip
cd /tmp && unzip alr.zip
mkdir -p ~/bin && cp bin/alr ~/bin/alr

# Install GNAT toolchain
alr toolchain --select gnat_native
alr toolchain --select gprbuild
```

## Building

```bash
# Set up environment
source setup_env.sh

# Build
gprbuild -P adam.gpr
```

## Running

```bash
./bin/main
```

## Testing

```bash
./bin/main 2>&1 | grep -E "^(Total|Passed|Failed)"
```

## Project Structure

```
adam/
├── src/
│   ├── main.adb            # Main entry point / demo
│   ├── mumps_types.ads     # MUMPS type definitions
│   ├── symbol_table.ads/adb # Symbol table with subscript support
│   ├── database.ads/adb    # Global database with persistence
│   ├── pattern.ads/adb     # Pattern matching (A, N, E, U, L, P, C)
│   ├── io.ads/adb          # I/O operations with device management
│   ├── string_funcs.ads/adb # String functions ($EXTRACT, $LENGTH, etc.)
│   ├── lexer.ads/adb       # MUMPS tokenizer (22 commands)
│   ├── parser.ads/adb      # AST generation
│   ├── runtime.ads/adb     # Expression evaluator + execution engine
│   └── conformance.adb     # Conformance test suite
├── examples/
│   ├── hello.mumps         # Hello World
│   ├── factorial.mumps     # Factorial calculation
│   └── fibonacci.mumps     # Fibonacci sequence
├── docs/
│   └── api.md              # API documentation
├── adam.gpr                # GNAT project file
├── setup_env.sh            # Environment setup script
├── SPRINTS.md              # Sprint plan
├── STATUS.md               # Status tracking
├── README.md               # This file
└── LICENSE                 # AGPL-3.0 license
```

## Features

### Symbol Table
- Variable storage and retrieval (SET, GET)
- Variable existence checking (EXISTS)
- Variable deletion (KILL)
- $DATA function (returns 0, 1, 10, or 11)
- Subscripted variable support: `X(1)`, `X(1,2,3)`
- $ORDER function for forward subscript traversal
- MERGE for deep copy of subscript trees
- Recursive KILL (kills node and all descendant subscripts)

### Database (Globals)
- Global variable storage and retrieval (`^GLOBAL`)
- Global variable existence checking
- Global variable deletion
- $DATA function for globals (full codes 0, 1, 10, 11)
- Subscripted global support: `^GLOBAL(1)`, `^GLOBAL(1,2,3)`
- $ORDER function for forward global traversal
- MERGE for deep copy of global subtrees
- Recursive KILL for globals
- Persistence: Save/Load to file

### Pattern Matching
- MUMPS pattern syntax: `3A`, `1A1N1A`, `3N`, etc.
- Pattern codes: A (alpha), N (numeric), E (everything), U (uppercase), L (lowercase), P (punctuation), C (control)
- Count specifications: exact (3A), range (2.5A), optional (.3A)

### I/O Operations
- Device management (open/close/use)
- Terminal I/O with cursor tracking
- File I/O (buffer-based)
- Write operations: Write, Write_Newline, Write_Form_Feed, Write_Tab, Write_Star
- Read operations: Read, Read_Star

### String Functions
- `$EXTRACT` - Extract substring by position
- `$LENGTH` - String length or piece count
- `$PIECE` - Extract delimited field
- `$TRANSLATE` - Character substitution/deletion
- `$ASCII` - ASCII code at position
- `$CHAR` - Character from ASCII code
- `$REVERSE` - Reverse a string
- `$JUSTIFY` - Right-justify with optional decimal precision
- `$FIND` - Find substring position
- `$SELECT` - Conditional value selection

### Lexer / Parser / Runtime
- Tokenizer for all 22 MUMPS commands
- AST generation with command and expression parsing
- Expression evaluator
- Program execution engine
- Control flow: SET, WRITE, HALT, QUIT, IF, KILL

## Status

**Version 0.7.0** - File I/O

- **174 conformance tests passing**
- **100% test success rate**
- **16 source modules, ~6,000 lines of Ada**
- **Expression evaluator with arithmetic, string, comparison, logical operators**
- **Function dispatch for $EXTRACT, $LENGTH, $PIECE, $TRANSLATE, $ASCII, $CHAR, $REVERSE, $JUSTIFY, $FIND, $DATA, $GET, $ORDER, $RANDOM, $SELECT**
- **Special variables: $T, $X, $Y, $H, $I, $J, $K, $S, $SYSTEM, $ECODE, $ETRAP**
- **Control flow: FOR loops, NEW scoping, ELSE, QUIT with return values**
- **Command execution: KILL, READ, MERGE, XECUTE**
- **File I/O: OPEN/CLOSE/USE with real file operations, EOF detection**

## Sprint History

| Sprint | Status | Tests |
|--------|--------|-------|
| S0: Environment Setup | ✅ Complete | - |
| S1: Core Types & Symbol Table | ✅ Complete | 23 |
| S2: Database Module | ✅ Complete | 46 |
| S3: Pattern Matching | ✅ Complete | 67 |
| S4: I/O Module | ✅ Complete | 82 |
| S5: String Functions | ✅ Complete | 104 |
| S6: Runtime / Interpreter | ✅ Complete | 113 |
| S7: Integration & Conformance | ✅ Complete | 113 |
| P2-S1: Expression Evaluator | ✅ Complete | 136 |
| P2-S2: Control Flow | ✅ Complete | 141 |
| P2-S3: Command Execution | ✅ Complete | 152 |
| P2-S4: Runtime String/Math Functions | ✅ Complete | 158 |
| P2-S5: Special Variables | ✅ Complete | 167 |
| P2-S6: File I/O | ✅ Complete | 174 |

## References

- [RFC](https://github.com/mjandrews1/rfc) - ReFaCtored Standard M
- [RSM](https://gitlab.com/Reference-Standard-M/rsm) - Reference Standard M
- [MUMPS Language Standard](https://www.iso.org/standard/59508.html)
- [Ada Programming Language](https://www.adaic.org/)
- [Alire - Ada Package Manager](https://alire.ada.dev/)
