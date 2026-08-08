# adam Sprint Plan — Phase 2

**Date:** 2026-08-08
**Goal:** Close critical gaps identified in GAP_ANALYSIS.md
**Baseline:** 113 tests, ~15-20% functional completeness

## Sprint Overview

| Sprint | Name | Duration | Priority | Depends On |
|--------|------|----------|----------|------------|
| P2-S1 | Expression Evaluator | 3-4 days | CRITICAL | — |
| P2-S2 | Control Flow | 3-4 days | CRITICAL | P2-S1 |
| P2-S3 | Command Execution | 2-3 days | CRITICAL | P2-S1 |
| P2-S4 | Runtime String/Math Functions | 2-3 days | HIGH | P2-S1 |
| P2-S5 | Special Variables | 1-2 days | HIGH | P2-S3 |
| P2-S6 | File I/O | 2-3 days | HIGH | P2-S3 |
| P2-S7 | NEW Scoping & Error Handling | 2-3 days | HIGH | P2-S2 |
| P2-S8 | Indirection (@) | 2-3 days | MEDIUM | P2-S1 |
| P2-S9 | Thread Safety & LOCK | 2-3 days | MEDIUM | P2-S3 |
| P2-S10 | Test Expansion | 3-4 days | HIGH | P2-S1 through P2-S9 |

**Total: ~22-32 days**

## Dependencies

```
P2-S1 (Expression Evaluator) ──────────────────────────── Foundation
├── P2-S2 (Control Flow: FOR, DO, NEW, GOTO, QUIT) ────── Requires P2-S1
├── P2-S3 (Command Execution: KILL, READ, MERGE, etc.) ── Requires P2-S1
├── P2-S4 (Runtime String/Math Functions) ──────────────── Requires P2-S1
│
├── P2-S5 (Special Variables) ──────────────────────────── Requires P2-S3
├── P2-S6 (File I/O) ──────────────────────────────────── Requires P2-S3
├── P2-S7 (NEW Scoping & Error Handling) ───────────────── Requires P2-S2
├── P2-S8 (Indirection) ────────────────────────────────── Requires P2-S1
└── P2-S9 (Thread Safety & LOCK) ───────────────────────── Requires P2-S3

P2-S10 (Test Expansion) ────────────────────────────────── Requires all above
```

## Sprint Details

### P2-S1: Expression Evaluator (3-4 days) — CRITICAL

**Goal:** Evaluate arithmetic, string, comparison, and logical expressions.

#### Tasks

- [ ] Update `parser.adb`:
  - [ ] `Parse_Expression` → `Parse_Or` → `Parse_And` → `Parse_Comparison` → `Parse_AddSub` → `Parse_MulDiv` → `Parse_Unary` → `Parse_Primary`
  - [ ] Binary operator nodes: `N_Add`, `N_Sub`, `N_Mul`, `N_Div`, `N_IntDiv`, `N_Mod`, `N_Pow`
  - [ ] String operators: `N_Concat`
  - [ ] Comparison operators: `N_Eql`, `N_Neql`, `N_Lt`, `N_Gt`, `N_Lte`, `N_Gte`
  - [ ] Logical operators: `N_And`, `N_Or`, `N_Not`
  - [ ] Function call nodes: `N_Func_Call` with function name and argument list

- [ ] Update `runtime.adb`:
  - [ ] `Eval_Expr` handles all binary/unary nodes
  - [ ] Arithmetic: `+`, `-`, `*`, `/`, `\` (integer divide), `#` (modulo), `**` (power)
  - [ ] String: `_` (concatenation)
  - [ ] Comparison: `=`, `'=`, `<`, `>`, `<=`, `>=`, `]` (follows), `]]` (sorts after)
  - [ ] Logical: `&`, `!`, `'` (not)
  - [ ] Function dispatch: `$EXTRACT`, `$LENGTH`, `$PIECE`, `$TRANSLATE`, `$ASCII`, `$CHAR`, `$REVERSE`, `$JUSTIFY`, `$FIND`, `$SELECT`
  - [ ] Function dispatch: `$DATA`, `$ORDER`, `$GET`
  - [ ] Subscripted variable access in expressions
  - [ ] Global variable access in expressions (`^GLOBAL`)

- [ ] Unit tests:
  - [ ] Arithmetic: `3+4`, `10-3`, `2*5`, `10/2`, `10\3`, `10#3`, `2**8`
  - [ ] String: `"hello"_"world"`
  - [ ] Comparison: `3>2`, `"abc"="abc"`, `"abc"]"abb"`
  - [ ] Logical: `1&1`, `1!0`, `'0`
  - [ ] Mixed: `3+4*2` (left-to-right: `(3+4)*2=14`, not `3+(4*2)=11`)
  - [ ] Functions: `$LENGTH("hello")`, `$EXTRACT("abcde",2,3)`, `$PIECE("a^b","^",2)`
  - [ ] Subscripts: `SET X(1)=42`, `WRITE X(1)`

**Acceptance Criteria:**
- [ ] `SET X = 3 + 4 * 2` evaluates to 14 (left-to-right)
- [ ] `WRITE $LENGTH("hello")` outputs 5
- [ ] `WRITE X(1)` outputs subscripted value
- [ ] All arithmetic, string, comparison operators work
- [ ] 30+ new tests

---

### P2-S2: Control Flow (3-4 days) — CRITICAL

**Goal:** Implement FOR, DO, NEW, GOTO, QUIT with return values, ELSE.

#### Tasks

- [ ] Update `parser.adb`:
  - [ ] FOR: Parse `FOR var=start:increment:end` syntax
  - [ ] FOR: Parse `FOR var=start:increment:end:command` syntax
  - [ ] FOR: Parse `FOR  command` (infinite loop)
  - [ ] FOR: Parse `FOR var=$ORDER(ref)` syntax
  - [ ] DO: Parse `DO label` and `DO label(args)` syntax
  - [ ] NEW: Parse `NEW var1,var2` list syntax
  - [ ] GOTO: Parse `GOTO label` syntax
  - [ ] QUIT: Parse `QUIT expr` (return value)
  - [ ] ELSE: Parse ELSE with $TEST check

- [ ] Update `runtime.adb`:
  - [ ] FOR execution: Initialize, check condition, execute body, increment, loop
  - [ ] DO execution: Push return address, jump to label, create NEW scope
  - [ ] QUIT with value: Return value from DO, pop scope
  - [ ] NEW execution: Push variable scope, save current values
  - [ ] GOTO execution: Jump to label in current routine
  - [ ] ELSE execution: Check $TEST, skip if true

- [ ] Add label table:
  - [ ] Build label→line mapping during parse
  - [ ] Support `tag+offset` syntax (`DO TAG+2`)

- [ ] Unit tests:
  - [ ] FOR loop: `FOR I=1:1:5 WRITE I,!`
  - [ ] DO/QUIT: `DO SUB ... SUB QUIT`
  - [ ] NEW/QUIT: `NEW X SET X=1 DO SUB WRITE X ... SUB NEW X SET X=2 QUIT`
  - [ ] GOTO: `GOTO TAG`
  - [ ] ELSE: `IF 0 ELSE WRITE "skipped"`
  - [ ] QUIT with value: `SET X=$$FUNC() ... FUNC QUIT 42`

**Acceptance Criteria:**
- [ ] FOR loops iterate correctly
- [ ] DO calls subroutine and returns
- [ ] NEW scopes variables correctly
- [ ] GOTO jumps to label
- [ ] QUIT returns values
- [ ] 20+ new tests

---

### P2-S3: Command Execution (2-3 days) — CRITICAL

**Goal:** Execute KILL, READ, MERGE, HANG, JOB, LOCK, BREAK, XECUTE via runtime.

#### Tasks

- [ ] Update `runtime.adb`:
  - [ ] KILL: Call `Symbol_Table.Kill_Var` or `Database.Kill_Global`
  - [ ] READ: Call `IO.Read`, store in variable
  - [ ] MERGE: Call `Symbol_Table.Merge_Var` or `Database.Merge_Global`
  - [ ] HANG: `Ada.Delays` for specified seconds
  - [ ] BREAK: Pause execution (debugger hook)
  - [ ] XECUTE: Parse and execute string as MUMPS code
  - [ ] JOB: Spawn process (stub or fork)
  - [ ] LOCK: Acquire/release locks (stub)

- [ ] Unit tests:
  - [ ] KILL: `SET X=1 KILL X WRITE $DATA(X)`
  - [ ] READ: `READ X` (with mock input)
  - [ ] MERGE: `MERGE ^B=^A`
  - [ ] HANG: `HANG 1` (verify delay)
  - [ ] XECUTE: `XECUTE "SET X=42"`

**Acceptance Criteria:**
- [ ] All 22 commands at least have runtime handlers
- [ ] KILL, READ, MERGE, HANG work end-to-end
- [ ] 15+ new tests

---

### P2-S4: Runtime String/Math Functions (2-3 days) — HIGH

**Goal:** Make string and math functions callable from MUMPS expressions.

#### Tasks

- [ ] Update `parser.adb`:
  - [ ] Parse `$NAME(args)` syntax in expressions
  - [ ] Map function names to `N_Func_Call` nodes
  - [ ] Support short forms: `$E`→`$EXTRACT`, `$L`→`$LENGTH`, `$P`→`$PIECE`, etc.

- [ ] Update `runtime.adb`:
  - [ ] Function dispatch table: name→Ada function
  - [ ] `$EXTRACT(str, pos1, pos2)` → `String_Funcs.Dollar_EXTRACT`
  - [ ] `$LENGTH(str)` / `$LENGTH(str, delim)` → `String_Funcs.Dollar_LENGTH`
  - [ ] `$PIECE(str, delim, p1, p2)` → `String_Funcs.Dollar_PIECE`
  - [ ] `$TRANSLATE(str, from, to)` → `String_Funcs.Dollar_TRANSLATE`
  - [ ] `$ASCII(str, pos)` → `String_Funcs.Dollar_ASCII`
  - [ ] `$CHAR(code)` → `String_Funcs.Dollar_CHAR`
  - [ ] `$REVERSE(str)` → `String_Funcs.Dollar_REVERSE`
  - [ ] `$JUSTIFY(str, width)` / `$JUSTIFY(num, w, d)` → `String_Funcs.Dollar_JUSTIFY`
  - [ ] `$FIND(str, sub, start)` → `String_Funcs.Dollar_FIND`
  - [ ] `$SELECT(cond1:expr1, cond2:expr2, ...)` → evaluate conditions
  - [ ] `$DATA(var)` → `Symbol_Table.Var_Data` / `Database.Global_Data`
  - [ ] `$ORDER(var)` → `Symbol_Table.Var_Order` / `Database.Global_Order`
  - [ ] `$GET(var)` / `$GET(var, default)` → return value or default

- [ ] Add math functions:
  - [ ] `$RANDOM(max)` → random integer 0..max-1
  - [ ] `$FNUMBER(num, format)` → formatted number
  - [ ] `$JUSTIFY` with decimals already implemented

- [ ] Unit tests:
  - [ ] `WRITE $LENGTH("hello")` → 5
  - [ ] `WRITE $EXTRACT("abcde",2,3)` → "bc"
  - [ ] `WRITE $PIECE("a^b^c","^",2)` → "b"
  - [ ] `WRITE $TRANSLATE("abc","ac","XY")` → "XbY"
  - [ ] `WRITE $ASCII("A")` → 65
  - [ ] `WRITE $CHAR(65)` → "A"
  - [ ] `WRITE $RANDOM(10)` → 0-9
  - [ ] `WRITE $DATA(X)` → 0/1/10/11
  - [ ] `WRITE $ORDER(X(""))` → first subscript

**Acceptance Criteria:**
- [ ] All string functions callable from MUMPS
- [ ] `$DATA`, `$ORDER`, `$GET` callable from MUMPS
- [ ] `$RANDOM` works
- [ ] 25+ new tests

---

### P2-S5: Special Variables (1-2 days) — HIGH

**Goal:** Make MUMPS special variables accessible from expressions.

#### Tasks

- [ ] Update `lexer.adb`:
  - [ ] Recognize `$T`, `$TEST`, `$X`, `$Y`, `$H`, `$HOROLOG`, `$I`, `$IO`, `$J`, `$JOB`, `$K`, `$KEY`, `$S`, `$STORAGE`, `$ECODE`, `$ETRAP`, `$SYSTEM`
  - [ ] Token type: `Tok_Special_Var`

- [ ] Update `runtime.adb`:
  - [ ] `$T` / `$TEST` → `Runtime.Get_Test_Result`
  - [ ] `$X` → `IO.Get_X(Current_Device)`
  - [ ] `$Y` → `IO.Get_Y(Current_Device)`
  - [ ] `$H` / `$HOROLOG` → days,seconds since 1840-12-31
  - [ ] `$I` / `$IO` → `IO.Current_Device`
  - [ ] `$J` / `$JOB` → process ID
  - [ ] `$K` / `$KEY` → last read terminator
  - [ ] `$S` / `$STORAGE` → available memory
  - [ ] `$ECODE` → error code
  - [ ] `$ETRAP` → error trap
  - [ ] `$SYSTEM` → "adam"

- [ ] Unit tests:
  - [ ] `WRITE $H` → current horolog
  - [ ] `WRITE $X` → cursor position
  - [ ] `IF 1 WRITE $T` → 1
  - [ ] `WRITE $SYSTEM` → "adam"

**Acceptance Criteria:**
- [ ] All common special variables accessible
- [ ] 10+ new tests

---

### P2-S6: File I/O (2-3 days) — HIGH

**Goal:** Real file I/O via OPEN/CLOSE/USE/READ/WRITE.

#### Tasks

- [ ] Update `io.adb`:
  - [ ] `Open_Device` with `File` kind → `Ada.Text_IO.Open`
  - [ ] `Close_Device` → `Ada.Text_IO.Close`
  - [ ] `Write` to file device → `Ada.Text_IO.Put`
  - [ ] `Read` from file device → `Ada.Text_IO.Get_Line`
  - [ ] File position tracking
  - [ ] `$ZA` (available bytes), `$ZEOF` (end of file)

- [ ] Update `parser.adb`:
  - [ ] OPEN: Parse `OPEN path` and `OPEN path:(parameters)` syntax
  - [ ] CLOSE: Parse `CLOSE path` syntax
  - [ ] USE: Parse `USE path` and `USE path:parameters` syntax

- [ ] Unit tests:
  - [ ] `OPEN "/tmp/test.txt":(write) USE ... WRITE "hello" CLOSE`
  - [ ] `OPEN "/tmp/test.txt":(read) USE ... READ X CLOSE`

**Acceptance Criteria:**
- [ ] Can write to files
- [ ] Can read from files
- [ ] OPEN/CLOSE/USE work end-to-end
- [ ] 10+ new tests

---

### P2-S7: NEW Scoping & Error Handling (2-3 days) — HIGH

**Goal:** Proper variable scoping and error trapping.

#### Tasks

- [ ] Add NEW stack to `symbol_table.adb`:
  - [ ] `Push_Scope` — save current variable values
  - [ ] `Pop_Scope` — restore saved values
  - [ ] `New_Var(name)` — save and clear specific variable
  - [ ] `New_All` — save and clear all variables

- [ ] Update `runtime.adb`:
  - [ ] DO pushes NEW scope
  - [ ] QUIT pops NEW scope
  - [ ] Error trap setting (`SET $ETRAP="label"`)
  - [ ] Error trapping on runtime errors
  - [ ] `$ECODE` and `$ZERROR` setting

- [ ] Unit tests:
  - [ ] `SET X=1 NEW X SET X=2 QUIT WRITE X` → 1
  - [ ] `SET $ETRAP="ERR" ... ERR WRITE $ECODE`

**Acceptance Criteria:**
- [ ] NEW scopes variables correctly
- [ ] QUIT restores scope
- [ ] Error trapping works
- [ ] 10+ new tests

---

### P2-S8: Indirection (@) (2-3 days) — MEDIUM

**Goal:** Implement MUMPS indirection operator.

#### Tasks

- [ ] Update `parser.adb`:
  - [ ] Parse `@var` as indirect variable reference
  - [ ] Parse `@var(args)` as indirect subscripted reference
  - [ ] Parse `@var` in SET target position

- [ ] Update `runtime.adb`:
  - [ ] Evaluate `@X` → look up value of X, use as variable name
  - [ ] Evaluate `@X(1)` → look up value of X, use as variable name with subscript
  - [ ] SET `@X = 42` → look up value of X, set that variable to 42

- [ ] Unit tests:
  - [ ] `SET X="Y" SET @X=42 WRITE Y` → 42
  - [ ] `SET X="Y" WRITE @X` → value of Y

**Acceptance Criteria:**
- [ ] Basic indirection works
- [ ] 5+ new tests

---

### P2-S9: Thread Safety & LOCK (2-3 days) — MEDIUM

**Goal:** Protect shared data structures and implement LOCK.

#### Tasks

- [ ] Add protected types:
  - [ ] `Protected_Symbol_Table` wrapping `Symbol_Table`
  - [ ] `Protected_Database` wrapping `Database`
  - [ ] `Protected_IO` wrapping `IO`

- [ ] Implement LOCK:
  - [ ] Lock table with timeout support
  - [ ] LOCK command: acquire lock
  - [ ] LOCK command: release lock (empty LOCK)
  - [ ] Deadlock detection (simple timeout)

- [ ] Unit tests:
  - [ ] Concurrent access to symbol table
  - [ ] LOCK/UNLOCK operations

**Acceptance Criteria:**
- [ ] No data corruption under concurrent access
- [ ] LOCK works
- [ ] 5+ new tests

---

### P2-S10: Test Expansion (3-4 days) — HIGH

**Goal:** Expand test suite from 113 to 400+ tests covering all new features.

#### Tasks

- [ ] Expression evaluator tests (50+):
  - [ ] Arithmetic operators (15 tests)
  - [ ] String operators (10 tests)
  - [ ] Comparison operators (15 tests)
  - [ ] Logical operators (10 tests)

- [ ] Control flow tests (40+):
  - [ ] FOR loops (15 tests)
  - [ ] DO/QUIT (10 tests)
  - [ ] NEW scoping (10 tests)
  - [ ] GOTO (5 tests)

- [ ] Command execution tests (30+):
  - [ ] KILL (10 tests)
  - [ ] READ (5 tests)
  - [ ] MERGE (5 tests)
  - [ ] HANG (5 tests)
  - [ ] XECUTE (5 tests)

- [ ] Function tests (40+):
  - [ ] String functions (20 tests)
  - [ ] Math functions (10 tests)
  - [ ] $DATA, $ORDER, $GET (10 tests)

- [ ] Special variable tests (15+):
  - [ ] $T, $X, $Y, $H, $I, $J (15 tests)

- [ ] File I/O tests (15+):
  - [ ] OPEN/CLOSE/USE (5 tests)
  - [ ] READ/WRITE to files (5 tests)
  - [ ] $ZA, $ZEOF (5 tests)

- [ ] Integration tests (20+):
  - [ ] Multi-line programs
  - [ ] Subroutine calls
  - [ ] Real MUMPS programs (hello, factorial, fibonacci)

**Acceptance Criteria:**
- [ ] 400+ tests total
- [ ] All tests passing
- [ ] All features covered

---

## Implementation Order

**Week 1:** P2-S1 (Expression Evaluator) — the foundation
**Week 2:** P2-S2 (Control Flow) + P2-S3 (Command Execution)
**Week 3:** P2-S4 (Runtime Functions) + P2-S5 (Special Variables)
**Week 4:** P2-S6 (File I/O) + P2-S7 (NEW Scoping)
**Week 5:** P2-S8 (Indirection) + P2-S9 (Thread Safety)
**Week 6:** P2-S10 (Test Expansion)

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Tests | 113 | 400+ |
| Commands executing | 5/22 | 22/22 |
| Expression evaluation | Stub | Full |
| String functions from MUMPS | 0 | 10+ |
| Special variables | 0 | 10+ |
| File I/O | Stub | Working |
| Functional completeness | ~15-20% | ~80-90% |
