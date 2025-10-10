format elf64
public _start

include 'lib.asm'

section '.bss' writable
char_buffer rb 1
output_buf  rb 100

section '.data' writable
input_error db "error: two filenames input expected", 0
file_opening_error db "error: file opening error", 0
letters_msg db "number of letters: "
digits_msg db "number of digits: "
newline db 0xA

section '.text' executable

_start:
   pop rcx
   cmp rcx, 3
   jne .input_error

   mov rdi,[rsp+8]
   mov rax, 2
   mov rsi, 0o
   syscall
   cmp rax, 0 
   jl .file_opening_error
   mov r8, rax

   xor r9, r9
   xor r10, r10

 .loop_read:
   mov rax, 0
   mov rdi, r8
   mov rsi, char_buffer
   mov rdx, 1 
   syscall
   cmp rax, 0
   je .next
   movzx rax, byte [char_buffer]

.check_digit:
    cmp al, '9'
    ja .check_letter

    cmp al, '0'
    jae .is_digit

    jmp .loop_read

.is_digit:
    inc r9
    jmp .loop_read

.check_letter:
    cmp al, 'A'
    jl .loop_read

    cmp al, 'Z'
    jle .is_letter

    cmp al, 'a'
    jl .loop_read

    cmp al, 'z'
    jle .is_letter

.is_letter:
    inc r10
    jmp .loop_read

.next: 
   mov rdi, r8
   mov rax, 3
   syscall

   mov rdi,[rsp+16] 
   mov rax, 2 
  mov rsi, 577 ;O_WRONLY|O_TRUNC|O_CREAT
  mov rdx, 777o
  syscall 
  cmp rax, 0 
  jl .file_opening_error

   mov rax, 1
   mov rdi, r8 
   mov rsi, letters_msg
   mov rdx, 19
   syscall
   
   mov rax, r10
   call number_str
   mov rax, rsi
   call len_str
   mov rdx, rax
   mov rax, r10
   call number_str

   mov rax, 1
   mov rdi, r8
   syscall

   mov rax, 1
   mov rdi, r8
   mov rsi, newline
   mov rdx, 1
   syscall

   mov rax, 1 ; write
   mov rdi, r8 ; дескриптор файла
   mov rsi, digits_msg ; данные
   mov rdx, 18 ; длина
   syscall
   
   mov rax, r9
   call number_str
   mov rax, rsi
   call len_str
   mov rdx, rax
   mov rax, r9
   call number_str

   mov rax, 1
   mov rdi, r8
   syscall

   mov rdi, r8
   mov rax, 3
   syscall



.exit:
   call exit

.input_error:
    mov rsi, input_error
    call print_str
    call error_exit

.file_opening_error:
    mov rsi, file_opening_error
    call print_str
    call new_line
    call error_exit