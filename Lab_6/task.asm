format ELF64

public _start

extrn initscr
extrn start_color
extrn init_pair
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
extrn attron

section '.bss' writable
    max_x dq 1
    max_y dq 1
    current_char dq 1
    delay dq 15000
    current_color_pair dq 1

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

    ;; Инициализация цветов
    call start_color

    ;; Инициализация цветовых пар
    mov rsi, 4
    mov rdx, 4
    mov rdi, 1
    call init_pair

    mov rsi, 0
    mov rdx, 0
    mov rdi, 2
    call init_pair

    ;; Настройка отображения
    xor rdi, rdi
    call curs_set
    call refresh
    call noecho
    call raw

    ;; Начальные значения
    mov rax, ' '
    mov [current_char], rax
    mov qword [current_color_pair], 1

mloop:
    xor r15, r15
    xor r8, r8    ; x
    xor r9, r9    ; y
    
h_move:
    ;; Устанавливаем позицию и выводим символ
    mov rsi, r8
    mov rdi, r9
    push r8
    push r9
    call move

    ;; Устанавливаем цвет
    mov rdi, [current_color_pair]
    shl rdi, 8
    call attron

    ;; Вывод символа
    mov rdi, [current_char]
    call addch
    
    ;; Обновление экрана
    call refresh
    
    ;; Задержка
    mov rdi, [delay]
    call usleep
    
    ;; Проверка ввода
    xor rdi, rdi
    call timeout
    call getch

    cmp rax, 'b'
    je exit_prog
    cmp rax, 'w'
    je ch_delay
    
    pop r9
    pop r8
    
    ;; Выбор направления движения
    cmp r15, 0
    je m_right
    jmp m_left

m_right:
    inc r8
    cmp r8, [max_x]
    jl h_move
    dec r8
    jmp v_move

m_left:
    dec r8
    cmp r8, 0
    jge h_move
    inc r8

v_move:
    ;; Движение по вертикали
    mov rsi, r8
    inc r9
    mov rdi, r9
    push r8
    push r9
    call move
    
    ;; Установка цвета и вывод
    mov rdi, [current_color_pair]
    shl rdi, 8
    call attron
    mov rdi, [current_char]
    call addch
    
    call refresh
    mov rdi, [delay]
    call usleep
    
    pop r9
    pop r8
    inc r9
    not r15
    
    ;; Проверка достижения низа экрана
    cmp r9, [max_y]
    jl h_move
    
    ;; Смена цвета при достижении края
    mov rdi, qword [current_color_pair]
    xor rdi, 3
    mov qword [current_color_pair], rdi
    jmp mloop

ch_delay:
    ;; Изменение скорости
    pop r9
    pop r8
    cmp qword [delay], 15000
    jne set_slow
    mov qword [delay], 5000
    jmp h_move
    
set_slow:
    mov qword [delay], 15000
    jmp h_move

exit_prog:
    call endwin
    call exit