# adam Sprint Plan — Phase 3

**Date:** 2026-08-08
**Goal:** Close critical gaps identified in GAP_ANALYSIS.md
**Baseline:** 253 tests, ~50-60% functional completeness

## Sprint Overview

| Sprint | Name | Duration | Priority | Issues |
|--------|------|----------|----------|--------|
| P3-S1 | Critical Fixes | 3-4 days | CRITICAL | #1, #3, #4, #5, #6 |
| P3-S2 | DO/QUIT Call Stack | 3-4 days | CRITICAL | #2, #10 |
| P3-S3 | Thread Safety Integration | 2-3 days | HIGH | #7, #8 |
| P3-S4 | Database Persistence | 2-3 days | HIGH | #9 |
| P3-S5 | I/O Enhancements | 2-3 days | HIGH | #11, #12, #16, #17 |
| P3-S6 | Control Flow Enhancements | 3-4 days | MEDIUM | #13, #14, #15 |
| P3-S7 | String/Math Functions | 2-3 days | MEDIUM | #18, #19 |
| P3-S8 | Error Handling & Special Variables | 2-3 days | MEDIUM | #20, #24, #25 |
| P3-S9 | Advanced Commands | 2-3 days | LOW | #21, #22, #23 |
| P3-S10 | Test Expansion | 3-4 days | HIGH | #25+ |

**Total: ~22-30 days**

## Dependencies

```
P3-S1 (Critical Fixes) ───────────────────────────────── Foundation
├── P3-S2 (DO/QUIT Call Stack) ────────────────────────── Requires P3-S1
├── P3-S3 (Thread Safety) ─────────────────────────────── Independent
├── P3-S4 (Database Persistence) ──────────────────────── Independent
├── P3-S5 (I/O Enhancements) ──────────────────────────── Independent
├── P3-S6 (Control Flow) ──────────────────────────────── Requires P3-S1
├── P3-S7 (String/Math Functions) ─────────────────────── Independent
├── P3-S8 (Error Handling) ────────────────────────────── Requires P3-S1
└── P3-S9 (Advanced Commands) ─────────────────────────── Requires P3-S1, P3-S2

P3-S10 (Test Expansion) ───────────────────────────────── Requires all above
```

## Sprint Details

### P3-S1: Critical Fixes (3-4 days) — CRITICAL

**Goal:** Fix the 6 critical issues that prevent running real MUMPS programs.

#### Tasks

- [ ] **Fix GOTO (#1)**
  - Update `Execute_Command` in `runtime.adb`
  - Look up target label in label table
  - Return target line pointer to `Execute_Line` or `Execute`
  - Continue execution from target line
  - Test: `GOTO TAG` jumps to TAG

- [ ] **Fix IF command chaining (#3)**
  - Add `Skip_Remainder` flag to `Runtime_State`
  - In `Execute_Command` for `N_If`, set `Skip_Remainder := True` when condition is false
  - Check `Skip_Remainder` in `Execute_Command` entry
  - Reset `Skip_Remainder` at start of each line
  - Test: `IF 0 SET X=1` does NOT set X

- [ ] **Wire WRITE format codes (#4)**
  - Update parser to handle `!`, `#`, `?col` in WRITE arguments
  - Create `N_Write_Newline`, `N_Write_Formfeed`, `N_Write_Tab` nodes
  - Update `Exec_Write` to dispatch to IO module
  - Test: `WRITE !` outputs newline, `WRITE #` outputs formfeed, `WRITE ?10` tabs

- [ ] **Fix $HOROLOG (#5)**
  - Implement using Ada.Calendar
  - Calculate days since 1840-12-31
  - Calculate seconds since midnight
  - Return "days,seconds" format
  - Test: `$H` returns valid timestamp

- [ ] **Fix $JOB (#6)**
  - Use Ada's process ID or system call
  - Return actual PID as string
  - Test: `$J` returns non-"1" value

**Acceptance Criteria:**
- [ ] GOTO jumps to label (not halts)
- [ ] IF 0 skips subsequent commands
- [ ] WRITE !, #, ?col work
- [ ] $H returns real timestamp
- [ ] $J returns real PID
- [ ] 15+ new tests

---

### P3-S2: DO/QUIT Call Stack (3-4 days) — CRITICAL

**Goal:** Implement proper subroutine calls with arguments and return values.

#### Tasks

- [ ] **Implement call stack**
  - Add `Call_Stack` to `Runtime_State`
  - Push return address on DO
  - Pop and jump on QUIT

- [ ] **DO with arguments**
  - Parse `DO label(arg1,arg2)` syntax
  - Pass arguments to subroutine
  - NEW arguments in subroutine scope

- [ ] **$$ extrinsic functions**
  - Parse `$$label(args)` syntax
  - Return value from QUIT
  - Store return value in expression

- [ ] **QUIT with return values**
  - Pop scope and return to caller
  - Return value for $$ functions

- [ ] **Tests**
  - `DO SUB` ... `SUB QUIT`
  - `DO SUB(1,2)` ... `SUB(a,b) QUIT`
  - `SET X=$$FUNC(42)` ... `FUNC(n) QUIT n*2`

**Acceptance Criteria:**
- [ ] DO calls subroutine and returns
- [ ] DO passes arguments
- [ ] $$ returns values
- [ ] QUIT returns to caller
- [ ] 10+ new tests

---

### P3-S3: Thread Safety Integration (2-3 days) — HIGH

**Goal:** Make runtime use protected types for thread-safe operation.

#### Tasks

- [ ] **Update runtime to use protected types**
  - Replace `Symbol_Table.Set_Var` with `Protected_Symbol_Table.Set_Var`
  - Replace `Database.Set_Global` with `Protected_Database.Set_Global`
  - Update all runtime operations

- [ ] **Fix Lock_Table**
  - Track lock names (not just count)
  - Implement per-variable locking
  - Add timeout-based deadlock detection

- [ ] **Add concurrent tests**
  - Test concurrent variable access
  - Test LOCK/UNLOCK operations
  - Test deadlock detection

**Acceptance Criteria:**
- [ ] Runtime uses protected types
- [ ] Lock_Table tracks per-variable locks
- [ ] Concurrent tests pass
- [ ] 5+ new tests

---

### P3-S4: Database Persistence (2-3 days) — HIGH

**Goal:** Test and harden database Save/Load functionality.

#### Tasks

- [ ] **Add Save/Load tests**
  - Test save to file
  - Test load from file
  - Test save/load with subscripts
  - Test save/load with globals

- [ ] **Improve format**
  - Escape tabs in values
  - Add version/magic number
  - Add error handling for file operations

- [ ] **Add atomic write**
  - Write to temp file
  - Rename on success
  - Rollback on failure

**Acceptance Criteria:**
- [ ] Save/Load tests pass
- [ ] Tabs in values handled correctly
- [ ] Atomic write prevents corruption
- [ ] 10+ new tests

---

### P3-S5: I/O Enhancements (2-3 days) — HIGH

**Goal:** Implement OPEN parameters and wire $ZA/$ZEOF.

#### Tasks

- [ ] **OPEN parameters (#11)**
  - Parse `OPEN path:(params)` syntax
  - Handle read/write/append modes
  - Handle timeout parameter

- [ ] **Wire $ZA and $ZEOF (#12)**
  - Add to special variable dispatch
  - $ZA: available bytes on current device
  - $ZEOF: end-of-file flag

- [ ] **Socket I/O (#16)**
  - Implement socket creation
  - Implement connect/listen/accept
  - Implement send/receive

- [ ] **Pipe I/O (#17)**
  - Implement named pipe creation
  - Implement pipe read/write

**Acceptance Criteria:**
- [ ] OPEN with parameters works
- [ ] $ZA and $ZEOF accessible
- [ ] Socket I/O works
- [ ] Pipe I/O works
- [ ] 15+ new tests

---

### P3-S6: Control Flow Enhancements (3-4 days) — MEDIUM

**Goal:** Implement argumentless FOR, FOR with $ORDER, and postconditionals.

#### Tasks

- [ ] **Argumentless FOR (#13)**
  - Parse `FOR  command` syntax
  - Loop until QUIT
  - Test: `FOR  SET X=X+1 QUIT:X>10`

- [ ] **FOR with $ORDER (#14)**
  - Parse `FOR I=$ORDER(^X(I))` syntax
  - Integrate with $ORDER function
  - Test: Traverse global subscripts

- [ ] **Command postconditionals (#15)**
  - Parse `command:expr` syntax
  - Evaluate expression before command
  - Skip command if expression is false
  - Test: `SET:cond X = 1`

**Acceptance Criteria:**
- [ ] Argumentless FOR works
- [ ] FOR with $ORDER works
- [ ] Postconditionals work
- [ ] 10+ new tests

---

### P3-S7: String/Math Functions (2-3 days) — MEDIUM

**Goal:** Implement $FNUMBER and $TEXT.

#### Tasks

- [ ] **$FNUMBER (#18)**
  - Parse `$FNUMBER(num, format, decimal)` syntax
  - Format number with commas, decimal points
  - Test: `$FNUMBER(1234567.89, "", 2)` → "1,234,567.89"

- [ ] **$TEXT (#19)**
  - Parse `$TEXT(label+offset)` syntax
  - Return source line at label
  - Test: `$TEXT(LABEL+2)` returns line

**Acceptance Criteria:**
- [ ] $FNUMBER formats numbers correctly
- [ ] $TEXT returns source lines
- [ ] 5+ new tests

---

### P3-S8: Error Handling & Special Variables (2-3 days) — MEDIUM

**Goal:** Fix error handling and implement NEW ALL.

#### Tasks

- [ ] **Fix error handling (#20)**
  - Make Raise_Error jump to trap label
  - Look up label in label table
  - Continue execution at error handler
  - Test: Error trap executes

- [ ] **Implement NEW ALL (#24)**
  - Parse `NEW` without arguments
  - Save all current variables
  - Create clean scope
  - Test: `NEW` clears all variables

- [ ] **Fix $STORAGE (#25)**
  - Return actual available memory
  - Use Ada's memory management
  - Test: $STORAGE returns real value

**Acceptance Criteria:**
- [ ] Error trap jumps to handler
- [ ] NEW ALL clears all variables
- [ ] $STORAGE returns real value
- [ ] 5+ new tests

---

### P3-S9: Advanced Commands (2-3 days) — LOW

**Goal:** Implement JOB, BREAK, VIEW commands.

#### Tasks

- [ ] **JOB (#21)**
  - Implement process spawning
  - Return job number
  - Test: `JOB ^routine` spawns process

- [ ] **BREAK (#22)**
  - Implement debugger hook
  - Pause execution
  - Allow variable inspection
  - Test: `BREAK` pauses program

- [ ] **VIEW (#23)**
  - Implement system parameter access
  - Read/write system parameters
  - Test: `VIEW "param"` returns value

**Acceptance Criteria:**
- [ ] JOB spawns processes
- [ ] BREAK pauses execution
- [ ] VIEW accesses parameters
- [ ] 5+ new tests

---

### P3-S10: Test Expansion (3-4 days) — HIGH

**Goal:** Expand test suite to 400+ tests.

#### Tasks

- [ ] **Edge case tests**
  - Empty strings
  - Very long strings
  - Unicode characters
  - Nested subscripts > 3 deep

- [ ] **Integration tests**
  - Full MUMPS programs
  - Recursive calls
  - Complex expressions
  - Multi-line programs

- [ ] **Stress tests**
  - Many variables (1000+)
  - Many subscripts
  - Large data values
  - Concurrent access

**Acceptance Criteria:**
- [ ] 400+ tests total
- [ ] All tests passing
- [ ] Edge cases covered
- [ ] Integration tests pass

---

## Implementation Order

**Week 1:** P3-S1 (Critical Fixes)
**Week 2:** P3-S2 (DO/QUIT Call Stack)
**Week 3:** P3-S3 (Thread Safety) + P3-S4 (Database Persistence)
**Week 4:** P3-S5 (I/O Enhancements) + P3-S7 (String/Math Functions)
**Week 5:** P3-S6 (Control Flow) + P3-S8 (Error Handling)
**Week 6:** P3-S9 (Advanced Commands) + P3-S10 (Test Expansion)

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Tests | 253 | 400+ |
| Commands executing | ~12/22 | 22/22 |
| Expression evaluation | Full | Full |
| String functions from MUMPS | 10 | 12+ |
| Special variables | 8 working | 10+ |
| File I/O | Working | Working + sockets/pipes |
| Functional completeness | ~50-60% | ~85-90% |
