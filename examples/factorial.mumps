; factorial.mumps - Calculate factorial in MUMPS
;
; This program demonstrates FOR loops and arithmetic operations.
; Calculates factorial of N using a FOR loop.

factorial(N) ;
    ; Calculate N! = N * (N-1) * ... * 1
    NEW result,i
    SET result = 1
    FOR i=1:1:N DO
    . SET result = result * i
    WRITE N,"! = ",result,!
    QUIT result

; Main entry point
main ;
    WRITE "Factorial Calculator",!
    WRITE "===================",!
    WRITE !
    WRITE "5! = ",$$factorial(5),!
    WRITE "10! = ",$$factorial(10),!
    WRITE "15! = ",$$factorial(15),!
    QUIT
