format ELF64
public _start

include 'lib.asm'

section '.bss' writable
a dq 0
b dq 0
c dq 0

section '.data' writable
error_args db "error: three arguments expected", 0
msg_x db "x = ", 0
msg_y db ", y = ", 0
newline db 0xA, 0
no_solutions db "No solutions found", 0xA, 0

section '.text' executable

is_perfect_square:
    push rbx
    push rcx
    push rdx
    push rsi
    
    cmp rdi, 0
    jl .not_square
    je .square_zero
    
    cmp rdi, 1
    je .square_one
    
    mov r8, rdi
    mov r9, rdi
    
    mov r10, r8
    inc r10
    shr r10, 1
    
.newton_loop:
    cmp r10, r8
    jge .newton_done
    
    mov r8, r10
    
    mov rax, r9
    xor rdx, rdx
    div r8
    add rax, r8
    shr rax, 1
    mov r10, rax
    
    jmp .newton_loop

.newton_done:
    mov rax, r8
    mul rax
    cmp rax, r9
    je .square
    jmp .not_square

.square_zero:
    mov rax, 0
    jmp .done

.square_one:
    mov rax, 1
    jmp .done

.square:
    mov rax, r8
    jmp .done

.not_square:
    mov rax, 0

.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

_start:
    pop rcx
    cmp rcx, 4
    jne .input_error

    pop rsi
    
    pop rsi
    call validate_number
    test rax, rax
    jz .input_error
    call str_number
    mov [a], rax
    
    pop rsi
    call validate_number
    test rax, rax
    jz .input_error
    call str_number
    mov [b], rax
    
    pop rsi
    call validate_number
    test rax, rax
    jz .input_error
    call str_number
    mov [c], rax
    
    mov rax, [b]
    cmp rax, 1
    jl .input_error
    
    mov rax, [c]
    cmp rax, 1
    jl .input_error
    
    mov r12, 1
    mov r15, 0
.x_loop:
    mov rax, r12
    cmp rax, [b]
    jg .check_solutions
    
    mov rax, [a]
    imul r12
    jo .next_x
    imul r12
    jo .next_x
    
    add rax, 1
    jo .next_x
    mov r13, rax
    
    cmp r13, 0
    jl .next_x
    
    mov rax, [c]
    mul rax
    test rdx, rdx
    jnz .check_square
    
    cmp r13, rax
    jg .next_x

.check_square:
    mov rdi, r13
    call is_perfect_square
    test rax, rax
    jz .next_x
    
    mov r14, rax

    cmp r14, 1
    jl .next_x
    cmp r14, [c]
    jg .next_x
    
    mov r15, 1
    mov rsi, msg_x
    call print_str
    
    mov rax, r12
    call print_number
    
    mov rsi, msg_y
    call print_str
    
    mov rax, r14
    call print_number
    
    call new_line

.next_x:
    inc r12
    jmp .x_loop

.check_solutions:
    cmp r15, 0
    jne .end_program
    mov rsi, no_solutions
    call print_str

.end_program:
    call exit

.input_error:
    mov rsi, error_args
    call print_str
    call new_line
    call error_exit