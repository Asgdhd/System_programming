format ELF64
public _start

include 'lib.asm'

section '.data' writeable
    ask_text db "waiting for a command: ", 0
    fail_text db "error: could not run programm", 10, 0
    clear_cmd db "reset", 0
    lab5_marker db "./lab5", 0
    cmd_line rb 256
    
    ; Параметры для запуска (команда + до 2 аргументов)
    cmd_args dq 0,0,0
    clear_args dq clear_cmd, 0
    
    ; Адрес списка переменных окружения
    environment dq 0
    
    result_code dd 0

section '.text' executable
_start:
    pop rcx
    lea rdi, [rsp + rcx*8 + 8] 
    mov [environment], rdi

command_loop:
    mov rsi, ask_text
    call print_str

    mov rsi, cmd_line
    call input_keyboard

    cmp byte [cmd_line], 0
    je command_loop

    call split_arguments

    mov rax, 57             ; sys_fork
    syscall

    test rax, rax
    js handle_fork_error
    jz execute_command
    
    jmp wait_completion

execute_command:
    ; Новая сессия для изоляции
    mov rax, 112            ; sys_setsid
    syscall
    
    mov rax, 59             ; sys_execve
    mov rdi, [cmd_args]
    lea rsi, [cmd_args]
    mov rdx, [environment]
    syscall

    mov rsi, fail_text
    call print_str
    call error_exit

wait_completion:
    mov rdi, rax            ; PID
    mov rax, 61             ; sys_wait4
    lea rsi, [result_code]
    mov rdx, 0
    mov r10, 0
    syscall

    ; Проверяем, не из lab5 ли команда
    call detect_lab5
    test rax, rax
    jz .no_cleanup
    
    ; Если из lab5, очищаем терминал
    call cleanup_terminal
    
.no_cleanup:
    jmp command_loop

handle_fork_error:
    jmp command_loop

split_arguments:
    lea rdi, [cmd_args]
    mov rcx, 3
    xor rax, rax
    rep stosq
    
    lea rsi, [cmd_line]
    lea rdi, [cmd_args]
    xor rcx, rcx 

.find_next:
    mov al, [rsi]
    test al, al
    jz .finish
    cmp al, ' '
    jne .found_arg
    inc rsi
    jmp .find_next

.found_arg:
    mov [rdi], rsi
    add rdi, 8
    inc rcx

.scan_arg:
    mov al, [rsi]
    test al, al
    jz .finish
    cmp al, ' '
    jne .keep_scanning
    mov byte [rsi], 0
    inc rsi
    jmp .find_next

.keep_scanning:
    inc rsi
    jmp .scan_arg

.finish:
    mov qword [rdi], 0
    ret

; Проверка на программу из lab5
; Результат: rax = 1 если да, 0 если нет
detect_lab5:
    push rsi
    push rdi
    push rbx
    
    mov rsi, [cmd_args]
    mov rdi, lab5_marker
    
.compare_chars:
    mov bl, [rdi]
    test bl, bl 
    jz .is_lab5
    
    mov bh, [rsi]
    cmp bh, bl
    jne .not_lab5
    
    inc rsi
    inc rdi
    jmp .compare_chars

.is_lab5:
    mov rax, 1
    jmp .exit_check

.not_lab5:
    xor rax, rax

.exit_check:
    pop rbx
    pop rdi
    pop rsi
    ret

cleanup_terminal:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 57             ; sys_fork
    syscall
    
    test rax, rax
    jnz .wait_cleanup
    
    ; Дочерний процесс запускает reset
    mov rax, 59             ; sys_execve
    mov rdi, clear_cmd
    lea rsi, [clear_args]
    mov rdx, [environment]
    syscall
    
    call error_exit

.wait_cleanup:
    mov rdi, rax            ; PID процесса reset
    mov rax, 61             ; sys_wait4
    lea rsi, [result_code]
    mov rdx, 0
    mov r10, 0
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret