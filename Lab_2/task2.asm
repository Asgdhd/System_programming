format ELF64

public _start
public exit

section '.data' writable
M db 5
K db 11
char db '&'
newline db 0xA

section '.text' executable
_start:
  mov al, [K]

  .row_iter:
    push rax
    mov bl,[M] 
    
    .col_iter:
        push rbx
        mov ecx, char
        mov eax, 4
        mov ebx, 1
        mov edx, 1
        int 0x80
        pop rbx
        dec rbx 
        cmp rbx, 0
        jne .col_iter

    mov eax, 4
    mov ebx, 1
    mov edx, 1
    mov ecx, newline
    int 0x80

    pop rax
    dec rax
    cmp rax, 0
    jne .row_iter
    call exit

section '.exit' executable 
exit:
  mov eax, 1
  xor ebx, ebx
  int 0x80