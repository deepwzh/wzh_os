[bits 32]
section .text
global put_int
;put_int(int8_t)
put_int:
global put_str
; put_str(char * s) 输出字符串
put_str:
pushad
mov ebx, [esp + 36]
mov ecx, 0
.put_char:
  mov al,[ebx]
  cmp al, 0
  jz .str_over
  push ax
  call put_char
  add esp, 2
  inc ebx
  jmp .put_char 
.str_over:
  popad
  ret
   
global put_char
;输出一个字符
put_char:
pushad
.get_cursor:
mov dx, 0x03d4
mov al, 0x0e
out dx, al
mov dx, 0x03d5
in al, dx
mov bh, al

mov dx, 0x03d4
mov al, 0fh
; out dx, al
out dx, al
mov dx, 0x03d5
in al, dx
mov bl, al


mov cl, [esp + 36] ;保存字符到cl中
cmp cl, 0x00; 0
jz .is_zero
cmp cl, 0x0d ;CR
jz .is_cr
cmp cl, 0x0a ;LR
jz .is_lf
cmp cl, 0x8 ;backspace
jz .is_bs
jmp .put_other

.is_zero:
nop
.is_cr:
nop
.is_lf:
nop
.is_bs:
nop
.put_other:
shl bx, 1
mov byte [gs:bx], cl
shr bx, 1
inc bx
jmp .set_cursor

.set_cursor:
mov dx, 0x03d4
mov al, 0x0e
mov al, bh
out dx, al
mov dx, 0x03d5
out dx, al
; mov bh, al

mov dx, 0x03d4
mov al, 0fh
; out dx, al
out dx, al
mov al, bl
mov dx, 0x03d5
out dx, al
; mov bl, al
popad
ret