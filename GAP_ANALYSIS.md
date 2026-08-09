# adam Gap Analysis

**Date:** 2026-08-08
**Status:** ~50-60% functionally complete vs. zigm reference

## Executive Summary

adam has solid foundations (parser, expression evaluator, symbol table, database) but several critical gaps prevent running real MUMPS programs. The parser recognizes all 22 commands but only ~12 actually execute end-to-end. Several special variables return fake values, GOTO is broken, DO/QUIT call stack is incomplete, and WRITE doesn't handle MUMPS format codes.

## Source Inventory

| File | Lines | Purpose |
|------|------:|---------|
| lexer.ads/adb | 97+387 | Tokenizer |
| parser.ads/adb | 105+608 | AST generation |
| runtime.ads/adb | 89+1217 | Execution engine |
| symbol_table.ads/adb | 68+380 | Local variables |
| database.ads/adb | 73+423 | Global variables |
| io.ads/adb | 81+318 | Device management |
| string_funcs.ads/adb | 65+249 | $-functions |
| pattern.ads/adb | 18+173 | Pattern matching |
| thread_safe.ads/adb | 51+149 | Protected types |
| mumps_types.ads | 36 | Type definitions |
| main.adb | 148 | Entry point |
| conformance.adb | 1191 | Test suite |
| conformance_expanded.adb | 638 | Extended tests |
| **Total** | **~6,500** | |

## Command Status

| # | Command | Status | Notes |
|---|---------|--------|-------|
| 1 | SET | ✅ Working | Subscripts, globals, indirection |
| 2 | WRITE | ⚠️ Partial | No `!`, `#`, `?col` format codes |
| 3 | READ | ⚠️ Basic | Terminal only, no timeout |
| 4 | FOR | ⚠️ Partial | Single body command, no argumentless FOR |
| 5 | IF | ⚠️ Partial | Sets $TEST but doesn't skip subsequent commands |
| 6 | ELSE | ✅ Working | |
| 7 | DO | ⚠️ Partial | Single label, no args, no $$ extrinsics |
| 8 | QUIT | ⚠️ Partial | No proper scope pop or return-to-caller |
| 9 | NEW | ✅ Working | Missing NEW ALL (no args) |
| 10 | KILL | ✅ Working | |
| 11 | GOTO | ❌ Broken | Sets halted, doesn't actually jump |
| 12 | MERGE | ✅ Working | |
| 13 | XECUTE | ✅ Working | |
| 14 | HALT | ✅ Working | |
| 15 | HANG | ✅ Working | |
| 16 | OPEN | ⚠️ Stub | Parser stub only |
| 17 | CLOSE | ⚠️ Stub | Parser stub only |
| 18 | USE | ⚠️ Stub | Parser stub only |
| 19 | LOCK | ⚠️ Broken | Doesn't track per-variable locks |
| 20 | BREAK | ❌ No-op | |
| 21 | JOB | ❌ No-op | |
| 22 | VIEW | ❌ No-op | |

## Critical Gaps

### 1. GOTO is Broken
- Just sets `Halted := True`
- Doesn't actually jump to label
- **Fix:** Change line pointer instead of halting

### 2. DO/QUIT Call Stack Incomplete
- DO works for single-line labels
- No args, no offset, no $$ extrinsics
- QUIT doesn't always pop scope correctly
- **Fix:** Implement proper call/return with scope push/pop

### 3. IF Doesn't Skip Commands
- IF 0 should skip remaining commands on same line
- Currently just sets $TEST flag
- **Fix:** Add Skip_Remainder flag like ELSE

### 4. WRITE Format Codes Missing
- `!` (newline), `#` (formfeed), `?col` (tab) exist in IO module
- Parser doesn't handle them in WRITE arguments
- **Fix:** Wire format codes in WRITE parser/exec

### 5. $HOROLOG Returns Fake Data
- Returns "0,0" instead of real time
- **Fix:** Implement days since 1840-12-31, seconds since midnight

### 6. $JOB Returns Hardcoded "1"
- **Fix:** Return actual PID

### 7. Thread Safety Not Integrated
- Protected types exist but runtime bypasses them
- Lock_Table doesn't track per-variable locks
- **Fix:** Make runtime use protected types

### 8. Database Persistence Untested
- Save/Load implemented but zero tests
- Tab-delimited format is fragile
- **Fix:** Add tests, improve format

## Priority Order

### P1 - Critical (blocks real MUMPS programs)
1. Fix GOTO (actual label jump)
2. Fix DO/QUIT call stack
3. Fix IF command chaining
4. Wire WRITE format codes (!, #, ?col)
5. Fix $HOROLOG (real time)
6. Fix $JOB (real PID)

### P2 - High (quality/completeness)
7. Integrate thread safety
8. Fix Lock_Table
9. Test database persistence
10. Implement $$ extrinsic functions
11. Implement OPEN parameters
12. Wire $ZA/$ZEOF

### P3 - Medium (feature completeness)
13. Argumentless FOR
14. FOR with $ORDER
15. Command postconditionals
16. Socket/pipe I/O
17. $FNUMBER
18. $TEXT
19. Fix error handling (trap dispatch)

### P4 - Low (parity)
20. Expand tests to 400+
21. JOB (process spawning)
22. BREAK
23. VIEW
24. NEW ALL
25. Real $STORAGE
