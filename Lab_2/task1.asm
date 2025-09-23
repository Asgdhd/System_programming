format ELF64

public _start

section '.data' writable
    place db ?
    S db 'qICelfwrMKpLbficRZvsmdvghv', 0

section '.text' executable
_start:
    mov rsi, S
    
push_chars:
    mov al, [rsi]
    cmp al, 0
    je pop_chars
    push ax
    inc rsi
    jmp push_chars

pop_chars:
    pop ax
    cmp ax, 0
    je new_line
    call print_char
    jmp pop_chars

new_line:
    mov al, 0xA
    call print_char
    jmp exit

print_char:
    mov [place], al
    mov eax, 4
    mov ebx, 1
    mov ecx, place
    mov edx, 1
    int 0x80
    ret

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80