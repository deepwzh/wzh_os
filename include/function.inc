; bp 字符串地址
; bx 起始字符串地址
; cx 字符串长度
; di 字符串偏移起始
print_str:
mov bp, message
mov bx, 80*2 ; 每行80个字符，跳到第二行
mov di,0
mov cx,13
.print:
mov al, [bp+di]
mov byte [gs:bx], al
add bx, 1
mov byte [gs:bx], 0xA4
add bx, 1
add di, 1
cmp cx, di
jnz .print
ret