format elf64
public _start

include 'lib.asm'

section '.bss' writable
char_buffer rb 1

section '.data' writable
input_error db "error: two filenames input expected", 0
file_opening_error db "error: file opening error", 0

section '.text' executable

_start:
    pop rcx
    cmp rcx, 3
    jne .input_error

    mov rdi, [rsp+8]
    mov rax, 2
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .file_opening_error
    mov r8, rax

    mov rdi, [rsp+16]
    mov rax, 2
    mov rsi, 577     ; O_WRONLY|O_CREAT|O_TRUNC
    mov rdx, 777o
    syscall
    cmp rax, 0
    jl .file_opening_error
    mov r9, rax

.loop_read:
    mov rax, 0
    mov rdi, r8
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    cmp rax, 0
    jle .close_files 

    mov al, [char_buffer]
    cmp al, 'A'
    je .loop_read
    cmp al, 'E'
    je .loop_read
    cmp al, 'I'
    je .loop_read
    cmp al, 'O'
    je .loop_read
    cmp al, 'U'
    je .loop_read
    cmp al, 'Y'
    je .loop_read

    mov rax, 1
    mov rdi, r9
    mov rsi, char_buffer
    mov rdx, 1
    syscall
    jmp .loop_read

.close_files:
    mov rax, 3
    mov rdi, r8
    syscall

    mov rax, 3
    mov rdi, r9
    syscall

    call exit

.input_error:
    mov rsi, input_error
    call print_str
    call new_line
    call error_exit

.file_opening_error:
    mov rsi, file_opening_error
    call print_str
    call new_line
    call error_exit