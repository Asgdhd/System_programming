format ELF64

public _start

include 'lib.asm'

section '.bss' writable
  buffer rb 255

section '.data' writable
    input_msg db "input positive number n:", 0xA, 0
    output_msg db "result: ", 0
    input_error db "error: positive number input expected", 0

section '.text' executable
_start:
    mov rsi, input_msg
    call print_str

    mov rsi, buffer
    call input_keyboard
    call validate_number
    test rax, rax
    je .input_error

    call str_number
    test rax, rax
    jle .input_error

    mov rbx, rax
    xor r8, r8
    .loop:
        mov rax, rbx
        mov rcx, rbx
        adc rcx, 4
        imul rcx
        adc rcx, 4
        imul rcx
        test rbx, 1
        jnz .substract
        adc r8, rax
        jmp .continue

   .substract:
        sbb r8, rax
        jmp .continue

    .continue:
        dec rbx
        test rbx, rbx
        jne .loop

    mov rsi, output_msg
    call print_str

    mov rax, r8
    call number_str
    
    call print_str
    call new_line

    .end:
        call exit
     
     .input_error:
        mov rsi, input_error
        call print_str
        call new_line
        call error_exit   
    
    