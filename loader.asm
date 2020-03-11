%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
mov ax, 0xb800
mov gs, ax
; mov byte [gs:0x00], '2'

mov bp, message
mov bx, 80*2 ; 每行80个字符，跳到第二行
mov di,0
mov cx,13
print:
mov al, [bp+di]
mov byte [gs:bx], al
add bx, 1
mov byte [gs:bx], 0xA4
add bx, 1
add di, 1
cmp cx, di
jnz print

message: db "Hello Loader!"