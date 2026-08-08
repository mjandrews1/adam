# adam Sprint Plan

**Project:** adam — M/MUMPS in Ada
**Repository:** https://github.com/mjandrews1/adam
**Created:** 2026-08-08

## Current State

- **Files:** 4 source files (~268 lines)
- **Status:** Very early scaffold
- **Compiler:** GNAT not installed (`brew install gcc` needed)
- **Blocking:** main.adb imports missing packages (Database, Pattern)

## Sprint Overview

| Sprint | Name | Duration | Status |
|--------|------|----------|--------|
| S0 | Environment Setup | 0.5 day | ✅ COMPLETE |
| S1 | Core Types & Symbol Table | 1-2 days | ✅ COMPLETE |
| S2 | Database Module | 2-3 days | ✅ COMPLETE |
| S3 | Pattern Matching | 1 day | ✅ COMPLETE |
| S4 | I/O Module | 1-2 days | ✅ COMPLETE |
| S5 | String Functions | 2-3 days | ✅ COMPLETE |
| S6 | Runtime / Interpreter | 5-7 days | ✅ COMPLETE |
| S7 | Integration & Conformance | 2-3 days | NOT STARTED |

**Total: ~15-22 days**

## Dependencies

```
S0 (Environment) ────────────────────────────────── Start first
├── S1 (Types & Symbol Table) ──► S5 (String Functions) ──► S6 (Runtime)
├── S2 (Database) ──────────────────────────────────────────► S6
├── S3 (Pattern Matching) ───────────────────────────────────► S6
├── S4 (I/O) ────────────────────────────────────────────────► S6
└── S7 (Integration & Conformance) ──────────────────────────┘
```

## Sprint Details

### S0: Environment Setup (0.5 day)

- [x] Install GNAT: `brew install gcc`
- [x] Verify: `gnatmake --version`
- [x] Create `adam.gpr` (GNAT project file)
- [x] Fix `main.adb` (remove imports of missing packages)
- [x] Verify compilation: `gnatmake -P adam.gpr`

### S1: Core Types & Symbol Table (1-2 days)

- [x] Complete `mumps_types.ads/adb` (add body file)
- [x] Fix `symbol_table.adb`:
  - [x] `Var_Data` — return codes 10/11 (subscripts only, both)
  - [x] `Var_Order` — forward/reverse subscript traversal
  - [x] `Merge_Var` — deep copy of subscript trees
- [x] Full subscript support
- [x] Unit tests (23 passing)

### S2: Database Module (2-3 days)

- [x] Create `database.ads` (specification)
- [x] Create `database.adb` (implementation)
- [x] Subscript support (mirror symbol_table for globals)
- [x] Binary file persistence
- [x] Unit tests (23 passing)

### S3: Pattern Matching (1 day)

- [x] Create `pattern.ads` (specification)
- [x] Create `pattern.adb` (implementation)
- [x] Pattern codes: A, N, E, U, L, P, C
- [x] Count specifications (3A, 1.5N, .3A)
- [x] Unit tests (21 passing)

### S4: I/O Module (1-2 days)

- [x] Create `io.ads` (specification)
- [x] Create `io.adb` (implementation)
- [x] Terminal I/O with cursor tracking
- [x] File I/O (open/close/read/write)
- [x] Unit tests (15 passing)

### S5: String Functions (2-3 days)

- [x] Create `string_funcs.ads/adb`
- [x] Implement: $EXTRACT, $LENGTH, $PIECE, $TRANSLATE
- [x] Implement: $ASCII, $CHAR, $REVERSE, $JUSTIFY
- [x] Implement: $FIND, $SELECT
- [x] Unit tests (22 passing)

### S6: Runtime / Interpreter (5-7 days)

- [x] Create `lexer.ads/adb` (tokenizer)
  - [x] All 22 MUMPS commands
  - [x] Short-form abbreviations
  - [x] Operators and literals
- [x] Create `parser.ads/adb` (AST generation)
  - [x] Expression hierarchy
  - [x] Command parsing
  - [x] Postconditions
- [x] Create `runtime.ads/adb` (execution engine)
  - [x] Expression evaluator
  - [x] Opcode dispatch
  - [x] Control flow (FOR, DO, IF/ELSE, QUIT, NEW, GOTO)
- [x] Unit tests (9 passing)

### S7: Integration & Conformance (2-3 days)

- [ ] Create `conformance.adb` (test suite)
  - [ ] Target: 400+ discrete tests
  - [ ] All 22 commands
  - [ ] All string/math functions
  - [ ] All pattern codes
- [ ] Create examples:
  - [ ] `examples/hello.mumps`
  - [ ] `examples/factorial.mumps`
  - [ ] `examples/fibonacci.mumps`
- [ ] Update `main.adb` (full integration demo)
- [ ] Update `README.md`
- [ ] Create `docs/api.md`

## Files to Create

| File | Sprint | Status |
|------|--------|--------|
| `adam.gpr` | S0 | ✅ EXISTS |
| `src/mumps_types.ads` | S1 | ✅ EXISTS |
| `src/conformance.adb` | S1 | ✅ EXISTS |
| `src/database.ads` | S2 | ✅ EXISTS |
| `src/database.adb` | S2 | ✅ EXISTS |
| `src/pattern.ads` | S3 | ✅ EXISTS |
| `src/pattern.adb` | S3 | ✅ EXISTS |
| `src/io.ads` | S4 | ✅ EXISTS |
| `src/io.adb` | S4 | ✅ EXISTS |
| `src/string_funcs.ads` | S5 | ✅ EXISTS |
| `src/string_funcs.adb` | S5 | ✅ EXISTS |
| `src/lexer.ads` | S6 | ✅ EXISTS |
| `src/lexer.adb` | S6 | ✅ EXISTS |
| `src/parser.ads` | S6 | ✅ EXISTS |
| `src/parser.adb` | S6 | ✅ EXISTS |
| `src/runtime.ads` | S6 | ✅ EXISTS |
| `src/runtime.adb` | S6 | ✅ EXISTS |
| `examples/hello.mumps` | S7 | MISSING |
| `examples/factorial.mumps` | S7 | MISSING |
| `examples/fibonacci.mumps` | S7 | MISSING |
| `docs/api.md` | S7 | MISSING |

## Known Issues

1. `main.adb` imports `Database` and `Pattern` which don't exist
2. `symbol_table.adb` has 3 stub operations (Var_Data, Var_Order, Merge_Var)
3. `mumps_types.ads` has no body file
4. `Var_Entry` type defined but unused (symbol table uses Hashed_Maps directly)
