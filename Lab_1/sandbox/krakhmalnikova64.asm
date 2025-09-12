format ELF64
public _start 
msg1 db "Krakhmalnikova", 0xA, 0 
msg2 db "Anastasia", 0xA, 0 
msg3 db "Ilyinichna", 0xA, 0 

_start:
    ;инициализация регистров для вывода информации на экран
    mov rax, 4
    mov rbx, 1
    mov rcx, msg1
    mov rdx, 16
    int 0x80
    ;инициализация регистров для вывода информации на экран
    mov rax, 4
    mov rbx, 1
    mov rcx, msg2
    mov rdx, 11
    int 0x80
    ;инициализация регистров для вывода информации на экран
    mov rax, 4
    mov rbx, 1
    mov rcx, msg3
    mov rdx, 12
    int 0x80
    ;инициализация регистров для успешного завершения работы программы
    mov rax, 1
    mov rbx, 0
    int 0x80