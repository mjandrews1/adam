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
| S1 | Core Types & Symbol Table | 1-2 days | NOT STARTED |
| S2 | Database Module | 2-3 days | NOT STARTED |
| S3 | Pattern Matching | 1 day | NOT STARTED |
| S4 | I/O Module | 1-2 days | NOT STARTED |
| S5 | String Functions | 2-3 days | NOT STARTED |
| S6 | Runtime / Interpreter | 5-7 days | NOT STARTED |
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

- [ ] Complete `mumps_types.ads/adb` (add body file)
- [ ] Fix `symbol_table.adb`:
  - [ ] `Var_Data` — return codes 10/11 (subscripts only, both)
  - [ ] `Var_Order` — forward/reverse subscript traversal
  - [ ] `Merge_Var` — deep copy of subscript trees
- [ ] Full subscript support
- [ ] Unit tests

### S2: Database Module (2-3 days)

- [ ] Create `database.ads` (specification)
- [ ] Create `database.adb` (implementation)
- [ ] Subscript support (mirror symbol_table for globals)
- [ ] Binary file persistence
- [ ] Unit tests

### S3: Pattern Matching (1 day)

- [ ] Create `pattern.ads` (specification)
- [ ] Create `pattern.adb` (implementation)
- [ ] Pattern codes: A, N, E, U, L, P, C
- [ ] Count specifications (3A, 1.5N, .3A)
- [ ] Unit tests

### S4: I/O Module (1-2 days)

- [ ] Create `io.ads` (specification)
- [ ] Create `io.adb` (implementation)
- [ ] Terminal I/O with cursor tracking
- [ ] File I/O (open/close/read/write)
- [ ] Unit tests

### S5: String Functions (2-3 days)

- [ ] Create `string_funcs.ads/adb`
- [ ] Implement: $EXTRACT, $LENGTH, $PIECE, $TRANSLATE
- [ ] Implement: $ASCII, $CHAR, $REVERSE, $JUSTIFY
- [ ] Implement: $FIND, $SELECT
- [ ] Unit tests

### S6: Runtime / Interpreter (5-7 days)

- [ ] Create `lexer.ads/adb` (tokenizer)
  - [ ] All 22 MUMPS commands
  - [ ] Short-form abbreviations
  - [ ] Operators and literals
- [ ] Create `parser.ads/adb` (AST generation)
  - [ ] Expression hierarchy
  - [ ] Command parsing
  - [ ] Postconditions
- [ ] Create `runtime.ads/adb` (execution engine)
  - [ ] Expression evaluator
  - [ ] Opcode dispatch
  - [ ] Control flow (FOR, DO, IF/ELSE, QUIT, NEW, GOTO)
- [ ] Unit tests

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
| `adam.gpr` | S0 | MISSING |
| `src/mumps_types.adb` | S1 | MISSING |
| `src/database.ads` | S2 | MISSING |
| `src/database.adb` | S2 | MISSING |
| `src/pattern.ads` | S3 | MISSING |
| `src/pattern.adb` | S3 | MISSING |
| `src/io.ads` | S4 | MISSING |
| `src/io.adb` | S4 | MISSING |
| `src/string_funcs.ads` | S5 | MISSING |
| `src/string_funcs.adb` | S5 | MISSING |
| `src/lexer.ads` | S6 | MISSING |
| `src/lexer.adb` | S6 | MISSING |
| `src/parser.ads` | S6 | MISSING |
| `src/parser.adb` | S6 | MISSING |
| `src/runtime.ads` | S6 | MISSING |
| `src/runtime.adb` | S6 | MISSING |
| `src/conformance.adb` | S7 | MISSING |
| `examples/hello.mumps` | S7 | MISSING |
| `examples/factorial.mumps` | S7 | MISSING |
| `examples/fibonacci.mumps` | S7 | MISSING |
| `docs/api.md` | S7 | MISSING |

## Known Issues

1. `main.adb` imports `Database` and `Pattern` which don't exist
2. `symbol_table.adb` has 3 stub operations (Var_Data, Var_Order, Merge_Var)
3. `mumps_types.ads` has no body file
4. `Var_Entry` type defined but unused (symbol table uses Hashed_Maps directly)
