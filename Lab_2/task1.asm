format ELF64

public _start
public exit

section '.data' writable
    S db 'qICelfwrMKpLbficRZvsmdvghv', 0
    char db ?

section '.text' executable
_start:
    mov rsi, S
    xor rax, rax
    push rax
    mov rax, 0xA
    push rax
  
push_chars:
    mov al, [rsi]
    inc rsi
    test al, al
    je pop_chars
    push rax
    jmp push_chars

pop_chars:
    pop rax
    test al, al
    je exit
    
    mov [char], al
    mov eax, 4
    mov ebx, 1
    mov ecx, char
    mov edx, 1
    int 0x80
    jmp pop_chars

section '.exit' executable    
exit:
    mov eax, 1
    mov ebx, 0
    int 0x80