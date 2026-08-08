; fibonacci.mumps - Fibonacci sequence in MUMPS
;
; This program demonstrates recursive function calls and
; subscripted variable storage.
; Calculates Fibonacci numbers using recursion and caching.

fibonacci(n) ;
    ; Return Nth Fibonacci number using recursion with caching
    NEW result
    ; Check cache
    IF $DATA(fib(n)) DO
    . SET result = fib(n)
    ELSE  DO
    . IF n<=1 DO
    . . SET result = n
    . ELSE  DO
    . . SET result = $$fibonacci(n-1) + $$fibonacci(n-2)
    . ; Cache the result
    . SET fib(n) = result
    QUIT result

; Main entry point
main ;
    WRITE "Fibonacci Sequence",!
    WRITE "==================",!
    WRITE !
    ; Clear cache
    KILL fib
    ; Print first 20 Fibonacci numbers
    FOR i=0:1:19 DO
    . WRITE "fib(",i,") = ",$$fibonacci(i),!
    WRITE !
    ; Show cached values
    WRITE "Cached values:",!
    SET sub=""
    FOR  SET sub=$ORDER(fib(sub)) QUIT:sub=""  DO
    . WRITE "fib(",sub,") = ",fib(sub),!
    QUIT
