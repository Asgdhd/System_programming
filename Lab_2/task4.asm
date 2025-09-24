format ELF64

public _start
public exit

section '.data' writable
  N dq 5607798014
  place db ?


section '.text' executable
_start:
  mov rax, [N]
  mov rcx, 10
  xor rsi, rsi

  count_sum:
    xor rdx, rdx
    div rcx
    add rsi, rdx    
    cmp rax, 0
    jne count_sum 

  mov rax, rsi
  xor rbx, rbx

  iter1:
    xor rdx, rdx
    div rcx
    add rdx, '0'
    push rdx
    inc rbx
    cmp rax, 0
    jne iter1 

  iter2:
    pop rax
    call print_symbl
    dec rbx
    cmp rbx, 0
    jne iter2  

  mov rax, 0xA
  call print_symbl
  call exit 

section '.print_symbl' executable
   print_symbl:
     push rbx
     push rdx
     push rcx
     push rax
     push rax
     mov eax, 4
     mov ebx, 1
     pop rdx
     mov [place], dl
     mov ecx, place
     mov edx, 1
     int 0x80
     pop rax
     pop rcx
     pop rdx
     pop rbx
     ret

section '.exit' executable    
  exit:
    mov eax, 1
    mov ebx, 0
    int 0x80