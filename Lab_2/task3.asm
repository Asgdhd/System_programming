format ELF64

public _start
public exit

section '.data' writable
  n db 10
  char db '&'
  place db ?


section '.text' executable
_start:
  xor rdx, rdx
  mov dl, [n]
  xor rbx, rbx
  iter1:
    inc rbx
    cmp rbx, rdx
    ja exit
    xor rcx, rcx

    iter2:
      inc rcx
      cmp rcx, rbx
      ja print_newline
      mov al, [char]
      call print_symbl
      
      jmp iter2

  print_newline:
    mov rax, 0xA
    call print_symbl
    jmp iter1

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