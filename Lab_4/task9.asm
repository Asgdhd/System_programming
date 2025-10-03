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

    mov rcx, rax

    mov rbx, 4
    div rbx

    cmp rdx, 1
    je .rem1

    cmp rdx, 2
    je .rem2

    cmp rdx, 3
    je .rem3

    neg rcx
    mov rax, rcx
    jmp .done

    .rem1:
        mov rax, 1
        jmp .done

    .rem2:
        mov rax, rcx
        add rax, 1
        jmp .done
    
    .rem3:
        mov rax, 0

    .done:
        mov rsi, output_msg
        call print_str

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
    
    