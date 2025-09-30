format ELF64

public _start

include 'lib2.asm'

section '.data' writable
    input_error db "error: invalid input, 3 numbers expected", 0
    arithmetic_overflow_error db "error: arithmetic overflow", 0

section '.text' executable
_start:
    pop rcx
    cmp rcx, 4
        jne .input_error

    pop rsi

    pop rsi
    call validate_number
    test rax, rax
    je .input_error
    call str_number
    mov r8, rax

    pop rsi
    call validate_number
    test rax, rax
    je .input_error

    pop rsi
    call validate_number
    test rax, rax
    je .input_error
    call str_number
    mov r9, rax

    ; Вычисления с проверкой переполнения
    mov rax, r8
    sub rax, r8
    jo .arithmetic_overflow    ; Проверка переполнения вычитания
    add rax, r8
    jo .arithmetic_overflow    ; Проверка переполнения сложения
    sub rax, r9
    jo .arithmetic_overflow    ; Проверка переполнения вычитания

    call print_number
    call new_line
    call exit
     
.input_error:
    mov rsi, input_error
    call print_str
    call new_line
    call error_exit   

.arithmetic_overflow:
    mov rsi, arithmetic_overflow_error
    call print_str
    call new_line
    call error_exit