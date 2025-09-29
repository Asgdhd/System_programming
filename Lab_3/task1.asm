format ELF64

public _start

include 'lib1.asm'

section '.data' writable
    no_input_error db "error: no input", 0
    input_error db "error: char input expected", 0

section '.text' executable
_start:
    pop rcx
    cmp rcx, 2
        jb .no_input_error

    mov rsi, [rsp + 8]

    .check_len:
        mov rax, rsi
        call len_str
        cmp rax, 1
        ja .input_error

    .print_ascii_code:
        movzx rax, byte [rsi]
        call print_number
        call new_line
        jmp .end
    
    .end:
        call exit
     
     .input_error:
        mov rsi, input_error
        call print_str
        call new_line
        call error_exit   
    
    .no_input_error:
        mov rsi, no_input_error
        call print_str
        call new_line
        call error_exit