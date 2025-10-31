format ELF64

public _start

include 'lib.asm'

section '.data' writable
    urandom db '/dev/urandom', 0
    error_args db 'error: directory name expected', 0xA, 0
    error_open_dir db 'error: cannot open directory', 0xA, 0
    error_open_urandom db 'error: cannot open /dev/urandom', 0xA, 0
    error_no_files db 'error: no regular files in directory', 0xA, 0
    error_chdir db 'error: cannot change directory', 0xA, 0
    current_dir db '.', 0

section '.bss' writable
    stat_buf rb 144
    dir_entries rb 8192
    file_list rq 256
    random_data rb 8
    processed_files rb 256

section '.text' executable
_start:
    pop rcx
    cmp rcx, 2
    jne .error_args

    mov rdi, [rsp + 8]
    
    mov rax, 80
    syscall
    cmp rax, 0
    jl .error_chdir
    
    mov rax, 2
    mov rdi, current_dir
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .error_open_dir
    mov r8, rax

    mov rax, 78
    mov rdi, r8
    mov rsi, dir_entries
    mov rdx, 8192
    syscall
    cmp rax, 0
    jle .error_no_files
    mov r9, rax

    mov rax, 3
    mov rdi, r8
    syscall

    xor r10, r10
    xor r11, r11
    lea r12, [file_list]

.scan_entries:
    cmp r11, r9
    jge .process_files
    
    movzx rcx, word [dir_entries + r11 + 16]
    
    mov al, [dir_entries + r11 + rcx - 1]
    cmp al, 8
    jne .next_entry
    
    mov al, [dir_entries + r11 + 18]
    cmp al, '.'
    je .next_entry
    
    lea rax, [dir_entries + r11 + 18]
    mov [r12 + r10 * 8], rax
    inc r10

.next_entry:
    add r11, rcx
    jmp .scan_entries

.process_files:
    test r10, r10
    jz .error_no_files

    call get_random
    xor rdx, rdx
    mov rcx, r10
    div rcx
    inc rdx
    mov r13, rdx

    mov rdi, processed_files
    mov rcx, 256
    xor al, al
    rep stosb

.process_loop:
    test r13, r13
    jz .exit

    call get_random
    xor rdx, rdx
    div r10
    mov r14, rdx

    mov al, [processed_files + r14]
    test al, al
    jnz .process_loop

    mov byte [processed_files + r14], 1

    mov rdi, [r12 + r14 * 8]

    call process_file

    dec r13
    jmp .process_loop

.error_args:
    mov rsi, error_args
    jmp .print_error

.error_open_dir:
    mov rsi, error_open_dir
    jmp .print_error

.error_chdir:
    mov rsi, error_chdir
    jmp .print_error

.error_no_files:
    mov rsi, error_no_files
    jmp .print_error

.error:
    mov rsi, error_open_dir

.print_error:
    call print_str
    call error_exit

.exit:
    call exit

process_file:
    push rdi
    push rsi
    push rdx
    push r8

    mov rax, 2
    mov rsi, 2
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .process_error
    mov r8, rax

    mov rax, 5
    mov rdi, r8
    mov rsi, stat_buf
    syscall
    cmp rax, 0
    jl .process_error

    mov rax, qword [stat_buf + 48]
    shl rax, 1

    mov rdi, r8
    mov rsi, rax
    mov rax, 77
    syscall
    cmp rax, 0
    jl .process_error

    mov rax, 3
    mov rdi, r8
    syscall

    jmp .process_exit

.process_error:

.process_exit:
    pop r8
    pop rdx
    pop rsi
    pop rdi
    ret

get_random:
    push rdi
    push rsi
    push rdx
    push rcx

    mov rax, 2
    mov rdi, urandom
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl .urandom_error
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    mov rsi, random_data
    mov rdx, 8
    syscall

    mov rax, 3
    mov rdi, r8
    syscall

    mov rax, qword [random_data]
    
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

.urandom_error:
    mov rsi, error_open_urandom
    call print_str
    call error_exit