;Function exit 
exit:
    mov rax, 60
    xor rdi, rdi
    syscall

error_exit:
    mov rax, 60
    mov rdi, 1
    syscall

;Function printing of string
;input rsi - place of memory of begin string
print_str:
    push rax
    push rdi
    push rdx
    push rcx
    mov rax, rsi
    call len_str
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rcx	
    pop rdx
    pop rdi
    pop rax
    ret

;The function makes new line
new_line:
    push rax
    mov rax, 0xA
    call print_char
    pop rax
    ret


;The function finds the length of a string
;input rax - place of memory of begin string
;output rax - length of the string
len_str:
  push rdx
  mov rdx, rax
  .iter:
      cmp byte [rax], 0
      je .next
      inc rax
      jmp .iter
  .next:
     sub rax, rdx
     pop rdx
     ret

;Function printing the number
;input rax - the number from the string
 print_number:

    push rax
    push rbx
    push rcx
    push rdx

    mov rcx, 10
    xor rbx, rbx
    iter1:
      xor rdx, rdx
      div rcx
      add rdx, '0'
      push rdx
      inc rbx
      cmp rax,0
    jne iter1
    iter2:
      pop rax
      call print_char
      dec rbx
      cmp rbx, 0
    jne iter2

 pop rdx
 pop rcx
 pop rbx
 pop rax
 ret

;Function printing the symbol
;input rax - symbol
;output: stdout
print_char:
    push rax
    push rdi
    push rsi
    push rdx
    mov [place], al
    mov rax, 1
    mov rdi, 1
    mov rsi, place
    mov rdx, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

section '.data' writable
place db 0 