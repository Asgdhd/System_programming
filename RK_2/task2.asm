format ELF64
include 'func.asm'
public _start

section '.bss' writable
    N dq 0
    array_ptr dq 0
    child_stack1 dq 0
    child_stack2 dq 0
    random_buf rb 4

section '.data' writable
    msg_even db "Сумма элементов с четными индексами: ", 0
    msg_odd db "Сумма элементов с нечетными индексами: ", 0
    msg_array db "Элементы массива: ", 0
    msg_err_args db "Ошибка: введите параметр N", 0xA, 0
    msg_err_alloc db "Ошибка выделения памяти", 0xA, 0
    msg_clone_err db "Ошибка создания процесса", 0xA, 0
    space db " ", 0
    urandom_file db "/dev/urandom", 0

section '.text' executable

fill_array_random:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, [array_ptr]
    mov r13, [N]

    mov rax, 2
    mov rdi, urandom_file
    mov rsi, 0
    syscall
    mov rbx, rax

    cmp rbx, 0
    jl .error

    xor r14, r14
.fill_loop:
    cmp r14, r13
    jge .fill_done

    mov rax, 0
    mov rdi, rbx
    mov rsi, random_buf
    mov rdx, 4
    syscall

    mov eax, dword [random_buf]
    and eax, 0x7FFFFFFF
    xor edx, edx
    mov ecx, 101
    div ecx
    movsxd rax, edx
    mov [r12 + r14*8], rax

    inc r14
    jmp .fill_loop

.fill_done:
    mov rax, 3
    mov rdi, rbx
    syscall

    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
.error:
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

print_array:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14

    mov r12, [array_ptr]
    mov r13, [N]

    mov rsi, msg_array
    call print_str

    xor r14, r14
.print_loop:
    cmp r14, r13
    jge .print_done

    mov rdi, [r12 + r14*8]
    call print_number

    mov rax, r14
    inc rax
    cmp rax, r13
    jge .no_space

    mov rsi, space
    call print_str

.no_space:
    inc r14
    jmp .print_loop

.print_done:
    call new_line
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

child_process1:
    mov r12, [array_ptr]
    mov r13, [N]
    xor r14, r14
    xor r15, r15

.sum_even_loop:
    cmp r15, r13
    jge .sum_even_done

    test r15, 1
    jnz .next_even

    mov rax, [r12 + r15*8]
    add r14, rax

.next_even:
    inc r15
    jmp .sum_even_loop

.sum_even_done:
    mov rsi, msg_even
    call print_str

    mov rdi, r14
    call print_number
    call new_line

    mov rax, 60
    xor rdi, rdi
    syscall

child_process2:
    mov r12, [array_ptr]
    mov r13, [N]
    xor r14, r14
    mov r15, 1

.sum_odd_loop:
    cmp r15, r13
    jge .sum_odd_done

    mov rax, [r12 + r15*8]
    add r14, rax

    add r15, 2
    jmp .sum_odd_loop

.sum_odd_done:
    mov rsi, msg_odd
    call print_str

    mov rdi, r14
    call print_number
    call new_line

    mov rax, 60
    xor rdi, rdi
    syscall

_start:
    pop rax
    cmp rax, 2
    jge .args_ok

    mov rsi, msg_err_args
    call print_str
    jmp exit_error

.args_ok:
    mov rsi, [rsp + 8]
    call str_number
    mov [N], rax

    mov rdi, rax
    shl rdi, 3
    call my_malloc
    test rax, rax
    jnz .alloc_ok

    mov rsi, msg_err_alloc
    call print_str
    jmp exit_error

.alloc_ok:
    mov [array_ptr], rax

    call fill_array_random

    call print_array

    ; Выделяем стек для первого процесса
    mov rdi, 8192
    call my_malloc
    test rax, rax
    jz .clone_error
    mov [child_stack1], rax
    add rax, 8192  ; Верхушка стека

    ; Создаем первый процесс (четные индексы)
    mov r10, rax    ; сохраняем указатель на стек
    mov rax, 56     ; sys_clone
    mov rdi, 0x11   ; SIGCHLD
    mov rsi, r10    ; стек
    xor rdx, rdx    ; ptid
    xor r10, r10    ; ctid
    xor r8, r8      ; newtls
    mov r9, child_process1  ; функция
    syscall

    cmp rax, 0
    jl .clone_error
    jz child_process1

    ; Выделяем стек для второго процесса
    mov rdi, 8192
    call my_malloc
    test rax, rax
    jz .clone_error
    mov [child_stack2], rax
    add rax, 8192  ; Верхушка стека

    ; Создаем второй процесс (нечетные индексы)
    mov r10, rax    ; сохраняем указатель на стек
    mov rax, 56     ; sys_clone
    mov rdi, 0x11   ; SIGCHLD
    mov rsi, r10    ; стек
    xor rdx, rdx    ; ptid
    xor r10, r10    ; ctid
    xor r8, r8      ; newtls
    mov r9, child_process2  ; функция
    syscall

    cmp rax, 0
    jl .clone_error
    jz child_process2

.parent_wait:
    mov rax, 61
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall

    cmp rax, 0
    jg .parent_wait

    ; Освобождаем память массива
    mov rdi, [array_ptr]
    call my_free

    ; Освобождаем стеки процессов
    mov rdi, [child_stack1]
    sub rdi, 8192
    call my_free

    mov rdi, [child_stack2]
    sub rdi, 8192
    call my_free

    mov rax, 60
    xor rdi, rdi
    syscall

.clone_error:
    mov rsi, msg_clone_err
    call print_str

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall