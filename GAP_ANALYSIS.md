# adam Gap Analysis

**Date:** 2026-08-08
**Status:** ~15-20% functionally complete vs. zigm reference

## Executive Summary

The lexer/parser infrastructure is solid, but the runtime barely executes anything. Only 5 of 22 commands actually execute. The expression evaluator is a stub — no arithmetic, no string concatenation, no function calls from MUMPS code.

## What Actually Works End-to-End

```mumps
SET X = "hello"
SET Y = 42
WRITE X
HALT
```

That is essentially it.

## Critical Gaps

### 1. Expression Evaluator (CRITICAL)
- `Parse_Expression` only calls `Parse_Primary` — no operator parsing
- `Eval_Expr` returns strings for literals/variables only
- `N_Binary_Op` and `N_Unary_Op` fall through to `return ""`
- **Impact:** `SET X = 3 + 4` does NOT work

### 2. Command Execution (CRITICAL)
Only 5 of 22 commands execute:

| Command | Status |
|---------|--------|
| SET | Partial (simple var=value only) |
| WRITE | Partial (no !, #, ?col format codes) |
| HALT | Complete |
| QUIT | Partial (sets halted flag, no return values, no NEW scope pop) |
| IF | Partial (sets $TEST, doesn't skip subsequent commands) |
| FOR, DO, NEW, GOTO, KILL, READ, MERGE, OPEN, CLOSE, USE, BREAK, HANG, JOB, LOCK, XECUTE, VIEW, ELSE | **Not executed** (null in runtime) |

### 3. No Arithmetic
Tokens are parsed but not evaluated:
- `+`, `-`, `*`, `/`, `\`, `#`, `**` — all ignored
- `_` (string concat) — ignored
- `&`, `!`, `'` (logical) — ignored

### 4. No Subscripted Variable Execution
Symbol table supports subscripts via Ada API, but:
- `SET X(1) = "foo"` doesn't work through runtime
- `SET ^GLOB = "bar"` doesn't work through runtime

### 5. String Functions Not Callable from MUMPS
- 10 functions exist as Ada library (`Dollar_EXTRACT`, etc.)
- Parser/runtime has no `$` function dispatch
- `$LENGTH("hello")` in MUMPS code does nothing

### 6. No Special Variables
- `$T`, `$X`, `$Y`, `$H`, `$I`, `$D`, `$O`, `$S`, `$J`, `$K` — none accessible
- Lexer has no `$` prefix handling for special variables

### 7. No Control Flow
- FOR: Parser stub (`Advance; -- Skip for now`)
- DO: Parser discards label reference
- NEW: AST node exists, no scope management
- GOTO: AST node exists, no label table
- ELSE: AST node exists, no $TEST check

### 8. Database Persistence Untested
- `Save()` and `Load()` implemented but zero tests
- Text-based tab-delimited format (fragile)
- No journal/WAL

### 9. No Thread Safety
- All global data structures are unprotected
- No mutex, semaphore, or protected objects

### 10. No Error Handling
- `$ECODE`, `$ESTACK`, `$ZERROR`, `$ETRAP` — not implemented
- Division by zero not handled
- Undefined variable returns empty string silently

## Recommended Priority

1. **Expression evaluator** — arithmetic, string ops, function dispatch, operator precedence
2. **FOR, DO, NEW, QUIT-with-return, GOTO** — core control flow
3. **KILL, READ, MERGE via runtime** — data manipulation
4. **Subscripted variables/globals in runtime** — MUMPS array access
5. **$DATA, $ORDER, $SELECT callable from MUMPS**
6. **Special variables** ($T, $X, $Y, $H, $I)
7. **OPEN/CLOSE/USE with real file I/O**
8. **Indirection (@)**
9. **NEW scoping and error handling**
10. **Thread safety**
11. **Expand tests to 400+**
