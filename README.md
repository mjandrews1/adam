# adam — M/MUMPS in Ada

A port of [RFC](https://github.com/mjandrews1/rfc) (a fork of [RSM](https://gitlab.com/Reference-Standard-M/rsm)) to the Ada programming language.

## Origin

- **RSM** — Reference Standard M by David Wicksell (Fourth Watch Software LC), derived from MUMPS V1 by Raymond Douglas Newman
- **RFC** — ReFaCtored Standard M, a fork of RSM by Mark J. Andrews
- **adam** — RFC ported to Ada

## License

AGPL-3.0-or-later (same as RSM and RFC)

## Prerequisites

GNAT (Ada compiler) must be installed:

```bash
# macOS - install GCC with Ada support
brew install gcc

# Or install GNAT Community Edition from AdaCore
# https://www.adacore.com/download
```

## Building

```bash
gnatmake -P adam.gpr
# or
gnatmake -o adam src/main.adb
```

## Running

```bash
./adam
```

## Project Structure

```
adam/
├── src/
│   ├── main.adb             # Main entry point
│   ├── mumps_types.ads      # Type definitions
│   ├── mumps_types.adb      # Type implementations
│   ├── symbol_table.ads     # Symbol table specification
│   ├── symbol_table.adb     # Symbol table implementation
│   ├── database.ads         # Database specification
│   ├── database.adb         # Database implementation
│   ├── lexer.ads            # Lexer specification
│   ├── lexer.adb            # Lexer implementation
│   ├── parser.ads           # Parser specification
│   ├── parser.adb           # Parser implementation
│   ├── runtime.ads          # Runtime specification
│   ├── runtime.adb          # Runtime implementation
│   ├── pattern.ads          # Pattern matching specification
│   ├── pattern.adb          # Pattern matching implementation
│   ├── io.ads               # I/O specification
│   ├── io.adb               # I/O implementation
│   └── conformance.adb      # Conformance tests
├── adam.gpr                 # GNAT project file
├── docs/
│   └── api.md               # API documentation
├── examples/
│   ├── hello.mumps          # Hello World
│   └── factorial.mumps      # Factorial
├── README.md
└── LICENSE
```

## Features

- **Symbol Table**: Local variable storage with subscript support
- **Database**: Global variable storage with subscript support
- **Lexer**: MUMPS tokenizer
- **Parser**: MUMPS parser with AST generation
- **Runtime**: MUMPS interpreter
- **Pattern Matching**: MUMPS pattern syntax (A, N, E, U, L)
- **I/O**: Terminal I/O operations
- **$DATA**: Returns 0, 1, 10, 11
- **$ORDER**: Forward and reverse subscript traversal
- **MERGE**: Deep copy of subscript trees

## Status

Project scaffolded. Awaiting GNAT compiler installation.

## References

- [RFC](https://github.com/mjandrews1/rfc) - ReFaCtored Standard M
- [RSM](https://gitlab.com/Reference-Standard-M/rsm) - Reference Standard M
- [MUMPS Language Standard](https://www.iso.org/standard/59508.html)
- [Ada Programming Language](https://www.adaic.org/)
