format elf64
public _start

extrn printf
extrn atof

section '.data' writable
    ; Массив значений x для тестирования (|x| < 1)
    x_values dq 0.0, 0.1, 0.5, -0.5, 0.9
    x_count dq ($ - x_values) / 8  ; Количество элементов в массиве
    
    ; Константы
    four         dq 4.0
    eight        dq 8.0
    
    ; Точность по умолчанию
    default_epsilon dq 0.0001
    
    ; Строки для вывода
    header      db "x               n             epsilon = %.10g", 10
                db "---------------------------------------------", 10, 0
    fmt         db "%-8.3f      %-12d", 10, 0
    error_msg   db "Ошибка: epsilon должен быть положительным числом", 10, 0

section '.bss' writable
    ; Вспомогательные переменные
    exact_result dq 0.0
    approx_result dq 0.0
    current_x dq 0.0
    two_n_plus_1 dq 0
    term_value dq 0.0
    cos_arg dq 0.0
    denom_sq dq 0.0
    epsilon  dq 0.0001
    diff     dq 0.0
    n_needed dq 0
    tmp      dq 0.0
    pi       dq 0.0
    pi_sq    dq 0.0
    pi_sq_over_8 dq 0.0

section '.text' executable

; Инициализация математических констант
init_constants:
    push rbp
    mov rbp, rsp
    
    ; Получаем π из FPU
    fldpi
    fst qword [pi]
    
    ; Вычисляем πˆ2
    fld qword [pi]
    fmul st0, st0
    fst qword [pi_sq]
    
    ; Вычисляем (πˆ2)/8
    fdiv qword [eight]
    fstp qword [pi_sq_over_8]
    
    pop rbp
    ret

; Вычисление точного значения
compute_exact:
    push rbp
    mov rbp, rsp
    
    ; Загружаем x и вычисляем |x|
    fld qword [current_x] 
    fabs
    
    ; Вычисляем π * |x| / 4
    fld qword [pi]
    fmulp
    fdiv qword [four]
    fstp qword [tmp]
    
    ; Вычисляем (πˆ2)/8 - π * |x| / 4
    fld qword [pi_sq_over_8]
    fsub qword [tmp]
    fstp qword [exact_result]
    
    pop rbp
    ret

; Вычисление ряда до заданной точности
compute_series_to_precision:
    push rbp
    mov rbp, rsp
    
    ; Обнуляем счетчик и сумму
    mov qword [approx_result], 0
    mov qword [n_needed], 0
    
    ; Цикл по членам ряда
    xor r14, r14            ; n = 0
    
.series_loop:
    ; Вычисляем (2n+1)
    mov rax, r14
    shl rax, 1
    inc rax
    mov [two_n_plus_1], rax
    
    ; Вычисляем член ряда
    ; (2n+1)*x
    fild qword [two_n_plus_1]
    fmul qword [current_x]
    fcos
    
    ; Делим на (2n+1)^2
    fild qword [two_n_plus_1]
    fmul st0, st0
    fdivp st1, st0
    
    ; Добавляем к сумме
    fadd qword [approx_result] ; st0 = approx + новый член
    fstp qword [approx_result] ; сохраняем новую сумму
    
    ; Увеличиваем счетчик
    inc qword [n_needed]
    inc r14
    
    ; Проверяем, достигли ли максимального количества итераций
    cmp r14, 10000000
    jge .max_iterations_reached
    
    ; Проверяем точность
    fld qword [exact_result]  ; st0 = точное значение
    fsub qword [approx_result]; st0 = разность
    fabs                      ; st0 = |разность|
    fstp qword [diff]         ; diff = |разность|
    
    ; Сравниваем с epsilon
    fld qword [diff]          ; st0 = diff
    fcomp qword [epsilon]     ; сравниваем
    fstsw ax
    sahf
    jb .precision_reached     ; если diff < epsilon
    
    jmp .series_loop

.precision_reached:
    pop rbp
    ret

.max_iterations_reached:
    pop rbp
    ret

_start:
    ; Проверяем аргументы командной строки
    mov rax, [rsp]          ; argc
    cmp rax, 2
    jl .use_default_epsilon
    
    ; Пытаемся преобразовать аргумент в число
    mov rdi, [rsp + 16]     ; argv[1]
    xor rax, rax
    call atof               ; результат в xmm0
    
    ; Проверяем, что epsilon > 0
    movq [tmp], xmm0
    fld qword [tmp]
    fldz
    fcomip st0, st1         ; сравниваем 0 с epsilon
    fstp st0                ; очищаем стек
    jae .epsilon_error      ; если epsilon <= 0
    
    ; Сохраняем epsilon
    movq [epsilon], xmm0
    jmp .init

.epsilon_error:
    ; Выводим сообщение об ошибке
    mov rdi, error_msg
    xor rax, rax
    call printf
    
    ; Используем значение по умолчанию
    movq xmm0, [default_epsilon]
    movq [epsilon], xmm0
    jmp .init

.use_default_epsilon:
    ; Используем значение по умолчанию
    movq xmm0, [default_epsilon]
    movq [epsilon], xmm0

.init:
    ; Инициализация математических констант
    call init_constants
    
    ; Инициализация FPU
    finit
    
    ; Вывод заголовка таблицы
    movq xmm0, [epsilon]
    mov rdi, header
    mov rax, 1
    call printf
    
    ; Подготовка цикла по значениям x
    mov rbx, [x_count]
    mov r12, x_values
    xor r13, r13

.main_loop:
    cmp r13, rbx
    jge .end_main_loop
    
    ; Загружаем текущее x
    mov rax, [r12 + r13*8]
    mov [current_x], rax
    
    ; Вычисляем точное значение
    call compute_exact
    
    ; Вычисляем ряд до заданной точности
    call compute_series_to_precision
    
    ; Выводим результат
    mov rdi, fmt
    movq xmm0, [current_x]
    mov rsi, [n_needed]
    mov rax, 1
    call printf
    
    ; Переходим к следующему x
    inc r13
    jmp .main_loop

.end_main_loop:
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall
