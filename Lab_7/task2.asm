format ELF64
public _start

include 'lib.asm'

SYS_OPEN    = 2
SYS_READ    = 0
SYS_CLOSE   = 3
SYS_MMAP    = 9
SYS_MUNMAP  = 11
SYS_FORK    = 57
SYS_WAIT4   = 61
SYS_WRITE   = 1

STDOUT      = 1
PROT_READ   = 0x1
PROT_WRITE  = 0x2
MAP_SHARED  = 0x01
MAP_ANONY   = 0x20

NUM_COUNT   = 667
MEM_SIZE    = NUM_COUNT * 4

section '.data' writeable
    start_msg      db "array is filled with random numbers", 10, 0
    urandom_path   db "/dev/urandom", 0
    
    msg_proc0      db "process 1: Количество чисел кратных пяти: ", 0
    msg_proc1      db "process 2: Третье после максимального: ", 0
    msg_proc2      db "process 3: 0.75 квантиль: ", 0
    msg_proc3      db "process 4: Пятое после минимального: ", 0
    
    mem_block     dq 0
    numbers       dq 0
    
section '.bss' writeable
    urandom_fd    dq 0
    random_buf    rd 1
    output_buffer rb 128
    num_buffer    rb 20

section '.text' executable
_start:
    ; Открытие /dev/urandom
    mov rax, SYS_OPEN
    mov rdi, urandom_path
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl exit_error
    mov [urandom_fd], rax

    ; Выделение разделяемой памяти
    mov rax, SYS_MMAP
    xor rdi, rdi
    mov rsi, MEM_SIZE
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_SHARED or MAP_ANONY
    mov r8, -1
    xor r9, r9
    syscall
    cmp rax, 0
    jl close_and_error
    mov [mem_block], rax
    mov [numbers], rax

    ; Заполнение массива случайными числами
    mov rdi, [numbers]
    mov rcx, NUM_COUNT
fill_array:
    call generate_random_from_urandom
    mov [rdi], eax
    add rdi, 4
    loop fill_array

    ; Закрытие /dev/urandom
    mov rax, SYS_CLOSE
    mov rdi, [urandom_fd]
    syscall

    mov rsi, start_msg
    call print_str

    ; Создание процессов
    mov r15, 0
create_processes:
    cmp r15, 4
    je wait_for_children
    mov rax, SYS_FORK
    syscall
    test rax, rax
    js exit_error
    jz process_code
    inc r15
    jmp create_processes

process_code:
    cmp r15, 0
    je count_multiples_of_five
    cmp r15, 1
    je find_third_max
    cmp r15, 2
    je find_quantile
    cmp r15, 3
    je find_fifth_min
    jmp process_done

count_multiples_of_five:
    mov rsi, [numbers]
    mov rcx, NUM_COUNT
    xor r14, r14
.check_loop:
    mov eax, [rsi]
    xor edx, edx
    mov ebx, 5
    div ebx
    test edx, edx
    jnz .next
    inc r14
.next:
    add rsi, 4
    loop .check_loop
    
    mov rdi, output_buffer
    mov rsi, msg_proc0
    call str_copy
    mov rax, output_buffer
    call len_str
    lea rdi, [output_buffer + rax]
    mov rax, r14
    mov rsi, rdi
    call number_str
    mov rax, output_buffer
    call len_str
    mov byte [output_buffer + rax], 10
    inc rax
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, output_buffer
    syscall
    jmp process_done

find_third_max:
    mov rsi, [numbers]
    mov rcx, NUM_COUNT
    mov r8, -1
    mov r9, -1
    mov r10, -1
.scan_loop:
    mov eax, [rsi]
    cmp eax, r8d
    jle .check_second
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, eax
    jmp .continue
.check_second:
    cmp eax, r8d
    je .continue
    cmp eax, r9d
    jle .check_third
    mov r10d, r9d
    mov r9d, eax
    jmp .continue
.check_third:
    cmp eax, r9d
    je .continue
    cmp eax, r10d
    jle .continue
    mov r10d, eax
.continue:
    add rsi, 4
    loop .scan_loop
    
    mov r14, r10
    mov rdi, output_buffer
    mov rsi, msg_proc1
    call str_copy
    mov rax, output_buffer
    call len_str
    lea rdi, [output_buffer + rax]
    mov rax, r14
    mov rsi, rdi
    call number_str
    mov rax, output_buffer
    call len_str
    mov byte [output_buffer + rax], 10
    inc rax
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, output_buffer
    syscall
    jmp process_done

find_quantile:
    ; Вычисление размера для копии массива
    mov rax, NUM_COUNT
    mov rbx, 4
    mul rbx
    mov r12, rax
    sub rsp, r12
    
    ; Копирование и сортировка массива
    mov rdi, rsp
    mov rsi, [numbers]
    mov rcx, NUM_COUNT
    rep movsd
    mov rdi, rsp
    mov rsi, NUM_COUNT
    call sort_array

    ; Вычисление индекса для 0.75 квантиля
    mov eax, NUM_COUNT
    dec eax
    mov ebx, 3
    mul ebx
    mov ebx, 4
    div ebx
    mov ebx, 4
    mul ebx
    mov eax, [rsp + rax]
    mov r14, rax
    add rsp, r12
    
    mov rdi, output_buffer
    mov rsi, msg_proc2
    call str_copy
    mov rax, output_buffer
    call len_str
    lea rdi, [output_buffer + rax]
    mov rax, r14
    mov rsi, rdi
    call number_str
    mov rax, output_buffer
    call len_str
    mov byte [output_buffer + rax], 10
    inc rax
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, output_buffer
    syscall
    jmp process_done

find_fifth_min:
    mov rsi, [numbers]
    mov rcx, NUM_COUNT
    mov r8, 0x7FFFFFFF
    mov r9, 0x7FFFFFFF
    mov r10, 0x7FFFFFFF
    mov r11, 0x7FFFFFFF
    mov r12, 0x7FFFFFFF
.scan_loop:
    mov eax, [rsi]
    cmp eax, r8d
    jge .check_second
    mov r12d, r11d
    mov r11d, r10d
    mov r10d, r9d
    mov r9d, r8d
    mov r8d, eax
    jmp .continue
.check_second:
    cmp eax, r8d
    je .continue
    cmp eax, r9d
    jge .check_third
    mov r12d, r11d
    mov r11d, r10d
    mov r10d, r9d
    mov r9d, eax
    jmp .continue
.check_third:
    cmp eax, r9d
    je .continue
    cmp eax, r10d
    jge .check_fourth
    mov r12d, r11d
    mov r11d, r10d
    mov r10d, eax
    jmp .continue
.check_fourth:
    cmp eax, r10d
    je .continue
    cmp eax, r11d
    jge .check_fifth
    mov r12d, r11d
    mov r11d, eax
    jmp .continue
.check_fifth:
    cmp eax, r11d
    je .continue
    cmp eax, r12d
    jge .continue
    mov r12d, eax
.continue:
    add rsi, 4
    loop .scan_loop
    
    mov r14, r12
    mov rdi, output_buffer
    mov rsi, msg_proc3
    call str_copy
    mov rax, output_buffer
    call len_str
    lea rdi, [output_buffer + rax]
    mov rax, r14
    mov rsi, rdi
    call number_str
    mov rax, output_buffer
    call len_str
    mov byte [output_buffer + rax], 10
    inc rax
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, output_buffer
    syscall

process_done:
    call exit

wait_for_children:
.wait_loop:
    mov rax, SYS_WAIT4
    mov rdi, -1
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    cmp rax, 0
    jg .wait_loop
    mov rax, SYS_MUNMAP
    mov rdi, [mem_block]
    mov rsi, MEM_SIZE
    syscall
    call exit

close_and_error:
    mov rax, SYS_CLOSE
    mov rdi, [urandom_fd]
    syscall
exit_error:
    call error_exit


str_copy:
    push rdi
    push rsi
    push rax
.loop:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rdi
    inc rsi
    jmp .loop
.done:
    pop rax
    pop rsi
    pop rdi
    ret

generate_random_from_urandom:
    push rdi
    push rsi
    push rdx
    push rcx
    mov rax, SYS_READ
    mov rdi, [urandom_fd]
    mov rsi, random_buf
    mov rdx, 4
    syscall
    mov eax, [random_buf]
    and eax, 0x7FFFFFFF
    xor edx, edx
    mov ecx, 10000
    div ecx
    mov eax, edx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция сортировки пузырьком
sort_array:
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    mov rcx, rsi
    dec rcx
    jz .sort_done
.outer_loop:
    mov rdx, 0
    mov r8, rcx
    shl r8, 2
.inner_loop:
    mov eax, [rdi + rdx]
    mov ebx, [rdi + rdx + 4]
    cmp eax, ebx
    jle .no_swap
    mov [rdi + rdx], ebx
    mov [rdi + rdx + 4], eax
.no_swap:
    add rdx, 4
    cmp rdx, r8
    jl .inner_loop
    loop .outer_loop
.sort_done:
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret