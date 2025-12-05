format ELF64

public _start

extrn initscr
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn stdscr
extrn move
extrn getch
extrn addch
extrn refresh
extrn endwin
extrn exit
extrn timeout
extrn curs_set
extrn usleep
extrn sin
extrn clear

section '.data' writable
    ; Параметры синусоиды
    amplitude   dq 8.0      ; A = 8.0
    frequency   dq 0.15     ; ω = 0.15
    step        dq 0.15     ; Шаг по x

    ; Символ для рисования
    sin_char    db '*'

section '.bss' writable
    max_x       dq 1
    max_y       dq 1
    delay       dq 50000    ; Задержка в микросекундах
    x_pos       dq 0.0      ; Текущая позиция x (вещественная)
    center_y    dq 0        ; Центр экрана по y

section '.text' executable

_start:
    ;; Инициализация ncurses
    call initscr
    mov rdi, [stdscr]

    ;; Получаем размеры экрана
    call getmaxx
    mov [max_x], rax
    call getmaxy
    mov [max_y], rax

    ;; Вычисляем центр экрана
    mov rax, [max_y]
    shr rax, 1
    mov [center_y], rax

    ;; Настройка отображения
    xor rdi, rdi
    call curs_set     ; Скрываем курсор
    call noecho
    call raw

main_loop:
    ;; Проверяем нажатие клавиши (без ожидания)
    xor rdi, rdi
    call timeout
    call getch

    cmp rax, 'q'      ; Выход при нажатии 'q'
    je exit_prog

    ;; Вычисляем y = A * sin(ω * x)
    movsd xmm0, [frequency]
    mulsd xmm0, [x_pos]

    ; Вызываем функцию sin из библиотеки C
    call sin

    ; A * sin(ω * x)
    mulsd xmm0, [amplitude]

    ; Преобразуем в целое и добавляем смещение к центру
    cvtsd2si rax, xmm0      ; Преобразуем double в int
    add rax, [center_y]     ; Смещаем к центру экрана

    ;; Проверяем границы экрана
    cmp rax, 0
    jge .check_upper
    mov rax, 0
.check_upper:
    cmp rax, [max_y]
    jl .store_y
    mov rax, [max_y]
    dec rax
.store_y:
    mov r9, rax     ; Сохраняем y (координата строки)

    ;; Получаем целую часть x для отображения
    movsd xmm0, [x_pos]
    cvtsd2si r8, xmm0      ; x для отображения (координата столбца)

    ;; Проверяем, находится ли точка на экране
    cmp r8, 0
    jl .skip_draw
    cmp r8, [max_x]
    jge .skip_draw
    cmp r9, 0
    jl .skip_draw
    cmp r9, [max_y]
    jge .skip_draw

    ;; Перемещаем курсор и рисуем символ
    mov rdi, r9
    mov rsi, r8
    call move
    movzx rdi, byte [sin_char]
    call addch

    ;; Обновляем экран
    call refresh

.skip_draw:

    ;; Увеличиваем x
    movsd xmm0, [x_pos]
    addsd xmm0, [step]
    movsd [x_pos], xmm0

    ;; Проверяем, достигли ли конца экрана
    cvtsi2sd xmm1, [max_x]
    comisd xmm0, xmm1
    jb .no_reset

    ;; Достигли конца экрана - очищаем и начинаем заново
    call clear
    call refresh
    pxor xmm0, xmm0
    movsd [x_pos], xmm0

.no_reset:

    ;; Задержка
    mov rdi, [delay]
    call usleep

    jmp main_loop

exit_prog:
    ;; Завершение программы
    call endwin

    ;; Завершаем процесс
    xor rdi, rdi
    call exit