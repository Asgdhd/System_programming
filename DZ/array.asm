format ELF64

public array_create
public array_get_len
public array_get
public array_set
public array_free
public array_push_back
public array_pop_front
public array_get_odd_numbers
public array_remove_evens
public array_count_ending_with_1

section '.bss' writable
    heap_start rq 1
    initial_brk rq 1

section '.text' executable

array_create:
    push rdi
    mov rax, 12
    xor rdi, rdi
    syscall
    mov [heap_start], rax
    mov [initial_brk], rax
    pop rdi
    push rdi
    inc rdi
    mov r8, rdi
    mov rdi, 8
    mov rax, r8
    mul rdi
    mov rdi, rax
    add rdi, [heap_start]
    mov rax, 12
    syscall
    cmp rax, 0
    jl .alloc_error
    mov rax, [heap_start]
    pop rdi
    mov [rax], rdi
    mov rcx, rdi
    test rcx, rcx
    jz .done
    mov r8, rax
    add r8, 8
    xor r9, r9
.clear_loop:
    mov qword [r8 + r9 * 8], 0
    inc r9
    cmp r9, rcx
    jl .clear_loop
.done:
    mov rax, [heap_start]
    add rax, 8
    ret
.alloc_error:
    pop rdi
    xor rax, rax
    ret

array_get_len:
    mov rax, [rdi - 8]
    ret

array_get:
    mov rcx, [rdi - 8]
    cmp rsi, rcx
    jae .out_of_bounds
    mov rax, [rdi + rsi * 8]
    ret
.out_of_bounds:
    xor rax, rax
    ret

array_set:
    mov rcx, [rdi - 8]
    cmp rsi, rcx
    jae .out_of_bounds
    mov [rdi + rsi * 8], rdx
    ret
.out_of_bounds:
    ret

array_free:
    mov rdi, [initial_brk]
    mov rax, 12
    syscall
    ret

array_push_back:
    push rdi
    push rsi
    push rbx
    push rcx
    push rdx
    
    mov rbx, rdi
    mov rcx, [rbx - 8]
    
    mov rdx, rcx
    inc rdx
    mov r8, rdx
    inc r8
    shl r8, 3
    
    mov rax, 12
    xor rdi, rdi
    syscall
    
    mov r9, rax
    mov rdi, [heap_start]
    sub r9, rdi
    
    cmp r9, r8
    jge .size_ok
    
    mov rax, 12
    mov rdi, [heap_start]
    add rdi, r8
    syscall
    cmp rax, 0
    jl .push_error

.size_ok:
    mov rax, [rbx - 8]
    inc rax
    mov [rbx - 8], rax
    
    mov rsi, [rsp + 24]
    mov rcx, rax
    dec rcx
    mov [rbx + rcx * 8], rsi
    
    mov rax, 1
    jmp .push_done

.push_error:
    xor rax, rax

.push_done:
    pop rdx
    pop rcx
    pop rbx
    pop rsi
    pop rdi
    ret

array_pop_front:
    push rdi
    push rbx
    push rcx
    push rdx
    push r12
    
    mov r12, rdi
    mov rcx, [r12 - 8]
    test rcx, rcx
    jz .empty_array
    
    mov rax, [r12]
    
    mov rbx, rcx
    dec rbx
    test rbx, rbx
    jz .update_length
    
    xor rdx, rdx
.shift_loop:
    mov r8, rdx
    inc r8
    mov r9, [r12 + r8 * 8]
    mov [r12 + rdx * 8], r9
    inc rdx
    cmp rdx, rbx
    jl .shift_loop

.update_length:
    mov rcx, [r12 - 8]
    dec rcx
    mov [r12 - 8], rcx
    jmp .pop_done

.empty_array:
    xor rax, rax

.pop_done:
    pop r12
    pop rdx
    pop rcx
    pop rbx
    pop rdi
    ret

array_get_odd_numbers:
    push r12
    push r13
    push r14
    push r15
    push rbx
    
    mov r12, rdi
    call array_get_len
    mov r13, rax
    xor r14, r14
    
    test r13, r13
    jz .create_empty
    
    xor r15, r15
.count_loop:
    mov rdi, r12
    mov rsi, r15
    push r14
    push r15
    call array_get
    pop r15
    pop r14
    
    test rax, 1
    jz .not_odd
    inc r14
.not_odd:
    inc r15
    cmp r15, r13
    jl .count_loop

.create_empty:
    mov rdi, r14
    push r14
    call array_create
    pop r14
    test rax, rax
    jz .error
    
    mov r15, rax
    xor rbx, rbx
    xor rcx, rcx
    
    test r13, r13
    jz .done
    
.fill_loop:
    mov rdi, r12
    mov rsi, rcx
    push rbx
    push rcx
    call array_get
    pop rcx
    pop rbx
    
    test rax, 1
    jz .skip_odd
    
    mov rdi, r15
    mov rsi, rbx
    mov rdx, rax
    push rbx
    push rcx
    call array_set
    pop rcx
    pop rbx
    
    inc rbx
    
.skip_odd:
    inc rcx
    cmp rcx, r13
    jl .fill_loop

.done:
    mov rax, r15
    jmp .cleanup

.error:
    xor rax, rax

.cleanup:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

array_remove_evens:
    push r12
    push r13
    push r14
    push r15
    push rbx

    mov r12, rdi
    call array_get_len
    mov r13, rax
    xor r14, r14

    test r13, r13
    jz .done

    xor r15, r15
.read_loop:
    mov rdi, r12
    mov rsi, r15
    call array_get
    mov rbx, rax

    test rbx, 1
    jz .next

    mov rdi, r12
    mov rsi, r14
    mov rdx, rbx
    call array_set
    inc r14

.next:
    inc r15
    cmp r15, r13
    jl .read_loop

    mov [r12 - 8], r14

.done:
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret
    
array_count_ending_with_1:
    push r12
    push r13
    push r14
    
    mov r12, rdi
    call array_get_len
    mov r13, rax
    xor r14, r14
    
    test r13, r13
    jz .done
    
    xor r15, r15
.count_loop:
    mov rdi, r12
    mov rsi, r15
    call array_get
    
    mov rbx, 10
    xor rdx, rdx
    div rbx
    
    cmp rdx, 1
    jne .not_ending_with_1
    inc r14
    
.not_ending_with_1:
    inc r15
    cmp r15, r13
    jl .count_loop

.done:
    mov rax, r14
    
    pop r14
    pop r13
    pop r12
    ret